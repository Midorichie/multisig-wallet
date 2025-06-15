;; Utility functions for multi-sig wallet
;; Enhanced with validation and helper functions

;; Constants
(define-constant ERR_INVALID_PRINCIPAL (err u200))
(define-constant ERR_EMPTY_LIST (err u201))

;; Helper function to check if address is a valid principal
(define-read-only (is-valid-principal (addr principal))
  ;; Check if principal is not the zero address equivalent
  (not (is-eq addr 'SP000000000000000000002Q6VF78)))

;; Utility function to validate amounts
(define-read-only (is-valid-amount (amount uint))
  (> amount u0))

;; Utility function to calculate percentage
(define-read-only (calculate-percentage (value uint) (percentage uint))
  (if (> percentage u100)
    u0
    (/ (* value percentage) u100)))

;; Function to get current timestamp (block height)
(define-read-only (get-current-time)
  block-height)

;; Function to check if enough time has passed
(define-read-only (time-elapsed (start-time uint) (required-blocks uint))
  (>= (- block-height start-time) required-blocks))

;; List utility functions
(define-read-only (list-length (items (list 10 principal)))
  (len items))

;; Function to validate a list of principals
(define-read-only (validate-principals (principals (list 10 principal)))
  (if (is-eq (len principals) u0)
    ERR_EMPTY_LIST
    (ok (fold check-principal-validity principals true))))

;; Private function to check each principal in fold
(define-private (check-principal-validity (principal-addr principal) (acc bool))
  (and acc (is-valid-principal principal-addr)))

;; Math utilities
(define-read-only (min (a uint) (b uint))
  (if (<= a b) a b))

(define-read-only (max (a uint) (b uint))
  (if (>= a b) a b))

;; Function to calculate required signatures based on total signers
(define-read-only (calculate-required-signatures (total-signers uint))
  (if (<= total-signers u1)
    u1
    (+ (/ total-signers u2) u1))) ;; More than half
