;; Utility functions for multi-sig wallet

(define-read-only (is-signer (addr principal))
  ;; TODO: check if `addr` is in signer-list
  false)
