;; Timelock contract for enhanced multi-sig wallet security
;; Adds time-based delays for critical operations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_TIMELOCK_NOT_EXPIRED (err u301))
(define-constant ERR_TIMELOCK_NOT_FOUND (err u302))
(define-constant ERR_ALREADY_EXECUTED (err u303))
(define-constant ERR_INVALID_DELAY (err u304))

;; Minimum delay periods (in blocks)
(define-constant MIN_DELAY u144) ;; ~1 day
(define-constant MAX_DELAY u1008) ;; ~1 week

;; Data variables
(define-data-var timelock-nonce uint u0)
(define-data-var default-delay uint MIN_DELAY)

;; Data structures
(define-map timelocks
  uint
  {
    target: principal,
    value: uint,
    data: (buff 128),
    executed: bool,
    eta: uint,
    created-by: principal
  })

(define-map authorized-addresses principal bool)

;; Initialize contract owner as authorized
(map-set authorized-addresses CONTRACT_OWNER true)

;; Read-only functions
(define-read-only (get-timelock (timelock-id uint))
  (map-get? timelocks timelock-id))

(define-read-only (get-default-delay)
  (var-get default-delay))

(define-read-only (is-authorized (addr principal))
  (default-to false (map-get? authorized-addresses addr)))

(define-read-only (get-current-nonce)
  (var-get timelock-nonce))

;; Public functions
(define-public (authorize-address (addr principal))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set authorized-addresses addr true))))

(define-public (revoke-authorization (addr principal))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq addr CONTRACT_OWNER)) ERR_UNAUTHORIZED)
    (ok (map-set authorized-addresses addr false))))

(define-public (queue-transaction (target principal) (value uint) (data (buff 128)) (delay uint))
  (let ((timelock-id (+ (var-get timelock-nonce) u1))
        (eta (+ block-height (max delay (var-get default-delay)))))
    (begin
      (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
      (asserts! (and (>= delay MIN_DELAY) (<= delay MAX_DELAY)) ERR_INVALID_DELAY)
      
      (map-set timelocks timelock-id {
        target: target,
        value: value,
        data: data,
        executed: false,
        eta: eta,
        created-by: tx-sender
      })
      
      (var-set timelock-nonce timelock-id)
      (ok timelock-id))))

(define-public (execute-transaction (timelock-id uint))
  (let ((timelock (unwrap! (map-get? timelocks timelock-id) ERR_TIMELOCK_NOT_FOUND)))
    (begin
      (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
      (asserts! (>= block-height (get eta timelock)) ERR_TIMELOCK_NOT_EXPIRED)
      (asserts! (not (get executed timelock)) ERR_ALREADY_EXECUTED)
      
      ;; Mark as executed
      (map-set timelocks timelock-id (merge timelock {executed: true}))
      
      ;; For now, we'll just transfer STX. In a full implementation,
      ;; this would execute arbitrary contract calls
      (if (> (get value timelock) u0)
        (as-contract (stx-transfer? (get value timelock) tx-sender (get target timelock)))
        (ok true)))))

(define-public (cancel-transaction (timelock-id uint))
  (let ((timelock (unwrap! (map-get? timelocks timelock-id) ERR_TIMELOCK_NOT_FOUND)))
    (begin
      (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (get executed timelock)) ERR_ALREADY_EXECUTED)
      
      ;; Remove the timelock
      (map-delete timelocks timelock-id)
      (ok true))))

(define-public (set-default-delay (new-delay uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (asserts! (and (>= new-delay MIN_DELAY) (<= new-delay MAX_DELAY)) ERR_INVALID_DELAY)
    (ok (var-set default-delay new-delay))))

;; Emergency functions
(define-public (emergency-pause)
  ;; This could be used to pause critical operations
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    ;; Implementation would set a pause flag
    (ok true)))
