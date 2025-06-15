;; Enhanced Multi-signature wallet contract with improvements
;; Allows multiple signers to collectively manage funds

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u103))
(define-constant ERR_PROPOSAL_ALREADY_EXECUTED (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))
(define-constant ERR_NOT_SIGNER (err u107))
(define-constant ERR_MINIMUM_SIGNERS (err u108))
(define-constant ERR_INVALID_THRESHOLD (err u109))
(define-constant ERR_CANNOT_REMOVE_SELF (err u110))
(define-constant ERR_PROPOSAL_EXPIRED (err u111))

;; Configuration constants
(define-constant MIN_SIGNERS u2)
(define-constant MAX_SIGNERS u10)
(define-constant PROPOSAL_EXPIRY_BLOCKS u1008) ;; ~1 week

;; Data variables
(define-data-var required-signatures uint u2)
(define-data-var proposal-nonce uint u0)
(define-data-var active-signers uint u1) ;; Track number of active signers

;; Data maps
(define-map signers principal bool)
(define-map proposals 
  uint 
  {
    destination: principal,
    amount: uint,
    signatures: uint,
    executed: bool,
    created-by: principal,
    created-at: uint,
    expires-at: uint
  })

(define-map proposal-votes {proposal-id: uint, voter: principal} bool)

;; Events (using print for logging)
(define-private (log-event (event-type (string-ascii 20)) (data (string-ascii 100)))
  (print {event: event-type, data: data, block: block-height}))

;; Initialize contract with initial signers
(map-set signers CONTRACT_OWNER true)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id))

(define-read-only (get-required-signatures)
  (var-get required-signatures))

(define-read-only (get-active-signers)
  (var-get active-signers))

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (default-to false (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})))

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

(define-read-only (is-signer (addr principal))
  (default-to false (map-get? signers addr)))

(define-read-only (is-proposal-expired (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (> block-height (get expires-at proposal))
    true))

;; Enhanced validation functions
(define-private (validate-threshold (threshold uint) (signer-count uint))
  (and 
    (>= threshold u1)
    (<= threshold signer-count)
    (> (* threshold u2) signer-count))) ;; Require more than 50%

;; Public functions
(define-public (add-signer (new-signer principal))
  (let ((current-signers (var-get active-signers)))
    (begin
      (asserts! (is-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (is-signer new-signer)) ERR_UNAUTHORIZED)
      (asserts! (< current-signers MAX_SIGNERS) ERR_UNAUTHORIZED)
      
      (map-set signers new-signer true)
      (var-set active-signers (+ current-signers u1))
      (log-event "SIGNER_ADDED" "New signer added")
      (ok true))))

(define-public (remove-signer (signer principal))
  (let ((current-signers (var-get active-signers)))
    (begin
      (asserts! (is-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (is-eq signer CONTRACT_OWNER)) ERR_UNAUTHORIZED)
      (asserts! (not (is-eq signer tx-sender)) ERR_CANNOT_REMOVE_SELF)
      (asserts! (is-signer signer) ERR_NOT_SIGNER)
      (asserts! (> current-signers MIN_SIGNERS) ERR_MINIMUM_SIGNERS)
      
      (map-set signers signer false)
      (var-set active-signers (- current-signers u1))
      
      ;; Adjust required signatures if necessary
      (let ((new-threshold (min (var-get required-signatures) (- current-signers u1))))
        (var-set required-signatures (max new-threshold u1)))
      
      (log-event "SIGNER_REMOVED" "Signer removed")
      (ok true))))

(define-public (create-proposal (destination principal) (amount uint))
  (let ((proposal-id (+ (var-get proposal-nonce) u1))
        (expires-at (+ block-height PROPOSAL_EXPIRY_BLOCKS)))
    (begin
      ;; Validations
      (asserts! (is-signer tx-sender) ERR_NOT_SIGNER)
      (asserts! (> amount u0) ERR_INVALID_AMOUNT)
      (asserts! (>= (get-contract-balance) amount) ERR_INSUFFICIENT_BALANCE)
      
      (map-set proposals proposal-id {
        destination: destination,
        amount: amount,
        signatures: u1,
        executed: false,
        created-by: tx-sender,
        created-at: block-height,
        expires-at: expires-at
      })
      
      ;; Creator automatically votes for their proposal
      (map-set proposal-votes {proposal-id: proposal-id, voter: tx-sender} true)
      (var-set proposal-nonce proposal-id)
      (log-event "PROPOSAL_CREATED" "New proposal created")
      (ok proposal-id))))

(define-public (vote-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND)))
    (begin
      ;; Validations
      (asserts! (is-signer tx-sender) ERR_NOT_SIGNER)
      (asserts! (not (has-voted proposal-id tx-sender)) ERR_ALREADY_VOTED)
      (asserts! (not (get executed proposal)) ERR_PROPOSAL_ALREADY_EXECUTED)
      (asserts! (<= block-height (get expires-at proposal)) ERR_PROPOSAL_EXPIRED)
      
      ;; Record vote and increment signature count
      (map-set proposal-votes {proposal-id: proposal-id, voter: tx-sender} true)
      (map-set proposals proposal-id 
        (merge proposal {signatures: (+ (get signatures proposal) u1)}))
      (log-event "VOTE_CAST" "Vote recorded")
      (ok true))))

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND)))
    (begin
      ;; Validations
      (asserts! (is-signer tx-sender) ERR_NOT_SIGNER)
      (asserts! (>= (get signatures proposal) (var-get required-signatures)) ERR_INSUFFICIENT_SIGNATURES)
      (asserts! (not (get executed proposal)) ERR_PROPOSAL_ALREADY_EXECUTED)
      (asserts! (<= block-height (get expires-at proposal)) ERR_PROPOSAL_EXPIRED)
      (asserts! (>= (get-contract-balance) (get amount proposal)) ERR_INSUFFICIENT_BALANCE)
      
      ;; Mark as executed
      (map-set proposals proposal-id (merge proposal {executed: true}))
      (log-event "PROPOSAL_EXECUTED" "Proposal executed")
      
      ;; Transfer funds
      (as-contract (stx-transfer? (get amount proposal) tx-sender (get destination proposal))))))

(define-public (deposit (amount uint))
  (begin
    (log-event "DEPOSIT" "Funds deposited")
    (stx-transfer? amount tx-sender (as-contract tx-sender))))

(define-public (set-required-signatures (new-threshold uint))
  (let ((current-signers (var-get active-signers)))
    (begin
      (asserts! (is-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (validate-threshold new-threshold current-signers) ERR_INVALID_THRESHOLD)
      (var-set required-signatures new-threshold)
      (log-event "THRESHOLD_UPDATED" "Signature threshold updated")
      (ok true))))

;; Emergency function to cancel expired proposals
(define-public (cleanup-expired-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND)))
    (begin
      (asserts! (> block-height (get expires-at proposal)) ERR_PROPOSAL_NOT_FOUND)
      (asserts! (not (get executed proposal)) ERR_PROPOSAL_ALREADY_EXECUTED)
      (map-delete proposals proposal-id)
      (ok true))))
