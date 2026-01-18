
;; -------------------------
(define-constant ERR-AUTH (err u300))
(define-constant ERR-NOT-FOUND (err u301))
(define-constant ERR-STATE (err u302))
(define-constant ERR-BALANCE (err u303))

;; -------------------------
;; Data Variables
;; -------------------------
(define-data-var treasury-balance uint u0)
(define-data-var member-count uint u0)
(define-data-var proposal-count uint u0)
(define-data-var approval-threshold uint u2) ;; minimum approvals

;; -------------------------
;; Maps
;; -------------------------

;; DAO Members
(define-map members principal bool)

;; Spending proposals
(define-map spend-proposals
  uint
  {
    proposer: principal,
    recipient: principal,
    amount: uint,
    approvals: uint,
    rejections: uint,
    executed: bool
  }
)

;; Approval tracking
(define-map approvals {proposal: uint, signer: principal} bool)

;; Reputation system
(define-map reputation principal uint)

;; -------------------------
;; Private Helpers
;; -------------------------

(define-private (is-member (user principal))
  (is-some (map-get? members user)))

(define-private (add-rep (user principal))
  (map-set reputation user (+ (default-to u0 (map-get? reputation user)) u1)))

;; -------------------------
;; Treasury Functions
;; -------------------------

;; Deposit STX into treasury
(define-public (deposit (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok true)))

;; -------------------------
;; Member Management
;; -------------------------

(define-public (add-member (new-member principal))
  (if (is-member tx-sender)
      (begin
        (map-set members new-member true)
        (var-set member-count (+ (var-get member-count) u1))
        (ok true))
      ERR-AUTH))

(define-public (remove-member (member principal))
  (if (is-member tx-sender)
      (begin
        (map-delete members member)
        (var-set member-count (- (var-get member-count) u1))
        (ok true))
      ERR-AUTH))

;; -------------------------
;; Proposal Functions
;; -------------------------

(define-public (create-spend-proposal (recipient principal) (amount uint))
  (if (is-member tx-sender)
      (let ((id (+ (var-get proposal-count) u1)))
        (map-set spend-proposals id {
          proposer: tx-sender,
          recipient: recipient,
          amount: amount,
          approvals: u0,
          rejections: u0,
          executed: false
        })
        (var-set proposal-count id)
        (ok id))
      ERR-AUTH))

(define-public (approve-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? spend-proposals proposal-id) ERR-NOT-FOUND)))
    (if (or (get executed proposal)
            (not (is-member tx-sender))
            (is-some (map-get? approvals {proposal: proposal-id, signer: tx-sender})))
        ERR-STATE
        (begin
          (map-set approvals {proposal: proposal-id, signer: tx-sender} true)
          (map-set spend-proposals proposal-id
            (merge proposal {approvals: (+ (get approvals proposal) u1)}))
          (add-rep tx-sender)
          (ok true)))))

(define-public (reject-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? spend-proposals proposal-id) ERR-NOT-FOUND)))
    (if (or (get executed proposal)
            (not (is-member tx-sender)))
        ERR-STATE
        (begin
          (map-set spend-proposals proposal-id
            (merge proposal {rejections: (+ (get rejections proposal) u1)}))
          (ok true)))))

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? spend-proposals proposal-id) ERR-NOT-FOUND)))
    (if (or (get executed proposal)
            (< (get approvals proposal) (var-get approval-threshold))
            (< (var-get treasury-balance) (get amount proposal)))
        ERR-STATE
        (begin
          (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
          (map-set spend-proposals proposal-id (merge proposal {executed: true}))
          (try! (stx-transfer? (get amount proposal)
                               (as-contract tx-sender)
                               (get recipient proposal)))
          (ok true)))))

;; -------------------------
;; Utility & Extended Functions
;; -------------------------

;; Short function: tip
;; Send small rewards from treasury to active members
(define-public (tip (member principal) (amount uint))
  (if (and (is-member tx-sender)
           (>= (var-get treasury-balance) amount))
      (begin
        (var-set treasury-balance (- (var-get treasury-balance) amount))
        (try! (stx-transfer? amount (as-contract tx-sender) member))
        (add-rep member)
        (ok true))
      ERR-AUTH))

;; Short function: quit
;; Member voluntarily leaves DAO
(define-public (quit)
  (if (is-member tx-sender)
      (begin
        (map-delete members tx-sender)
        (var-set member-count (- (var-get member-count) u1))
        (ok true))
      ERR-AUTH))

;; Short function: burn
;; Permanently reduce treasury balance (deflation / reset)
(define-public (burn (amount uint))
  (if (and (is-member tx-sender)
           (>= (var-get treasury-balance) amount))
      (begin
        (var-set treasury-balance (- (var-get treasury-balance) amount))
        (ok true))
      ERR-STATE))

;; -------------------------
;; Governance Settings
;; -------------------------

(define-public (update-threshold (new-threshold uint))
  (if (is-member tx-sender)
      (begin
        (var-set approval-threshold new-threshold)
        (ok true))
      ERR-AUTH))

;; -------------------------
;; Read-only Functions
;; -------------------------

(define-read-only (is-dao-member (user principal))
  (is-member user))

(define-read-only (get-treasury-balance)
  (var-get treasury-balance))

(define-read-only (get-proposal (proposal-id uint))
  (map-get? spend-proposals proposal-id))

(define-read-only (get-reputation (user principal))
  (default-to u0 (map-get? reputation user)))

