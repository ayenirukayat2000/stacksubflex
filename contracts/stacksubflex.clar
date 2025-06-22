;; --------------------------------------------------
;; Contract: SubChainFlex
;; Description: Enhanced micro-payment subscription protocol with admin control
;; --------------------------------------------------

(define-data-var plan-counter uint u1)
(define-data-var contract-admin principal tx-sender)

(define-map plans
  uint
  {
    provider: principal,
    fee: uint,
    interval: uint,
    metadata: (string-ascii 100),
    active: bool
  }
)

(define-map subscriptions
  { subscriber: principal, plan-id: uint }
  {
    start-block: uint,
    next-payment-block: uint,
    active: bool
  }
)

;; === Create Plan ===
(define-public (create-plan (fee uint) (interval uint) (metadata (string-ascii 100)))
  (let ((id (var-get plan-counter)))
    (begin
      (map-set plans id {
        provider: tx-sender,
        fee: fee,
        interval: interval,
        metadata: metadata,
        active: true
      })
      (var-set plan-counter (+ id u1))
      (ok id)
    )
  )
)

;; === Subscribe ===
(define-public (subscribe (plan-id uint))
  (match (map-get? plans plan-id)
    plan
    (begin
      (asserts! (get active plan) (err u105)) ;; Plan inactive
      (try! (stx-transfer? (get fee plan) tx-sender (get provider plan)))
      (map-set subscriptions { subscriber: tx-sender, plan-id: plan-id } {
        start-block: stacks-block-height,
        next-payment-block: (+ stacks-block-height (get interval plan)),
        active: true
      })
      (ok true)
    )
    (err u100)
  )
)

;; === Process payment ===
(define-public (process-payment (subscriber principal) (plan-id uint))
  (match (map-get? subscriptions { subscriber: subscriber, plan-id: plan-id })
    sub
    (if (and (get active sub) (>= stacks-block-height (get next-payment-block sub)))
        (match (map-get? plans plan-id)
          plan
          (begin
            (asserts! (get active plan) (err u105))
            (try! (stx-transfer? (get fee plan) subscriber (get provider plan)))
            (map-set subscriptions { subscriber: subscriber, plan-id: plan-id } {
              start-block: (get start-block sub),
              next-payment-block: (+ stacks-block-height (get interval plan)),
              active: true
            })
            (ok true)
          )
          (err u101)
        )
        (err u102)
    )
    (err u103)
  )
)

;; === Cancel subscription ===
(define-public (cancel-subscription (plan-id uint))
  (let ((key { subscriber: tx-sender, plan-id: plan-id }))
    (match (map-get? subscriptions key)
      sub
      (begin
        (map-set subscriptions key (merge sub { active: false }))
        (ok true)
      )
      (err u103)
    )
  )
)

;; === Pause or resume plan (provider) ===
(define-public (toggle-plan-status (plan-id uint))
  (match (map-get? plans plan-id)
    plan
    (begin
      (asserts! (is-eq tx-sender (get provider plan)) (err u106))
      (map-set plans plan-id (merge plan { active: (not (get active plan)) }))
      (ok (not (get active plan)))
    )
    (err u100)
  )
)

;; === Update plan (provider) ===
(define-public (update-plan (plan-id uint) (fee uint) (interval uint) (metadata (string-ascii 100)))
  (match (map-get? plans plan-id)
    plan
    (begin
      (asserts! (is-eq tx-sender (get provider plan)) (err u106))
      (map-set plans plan-id {
        provider: (get provider plan),
        fee: fee,
        interval: interval,
        metadata: metadata,
        active: (get active plan)
      })
      (ok true)
    )
    (err u100)
  )
)

;; === Transfer plan ownership ===
(define-public (transfer-plan (plan-id uint) (new-provider principal))
  (match (map-get? plans plan-id)
    plan
    (begin
      (asserts! (is-eq tx-sender (get provider plan)) (err u106))
      (map-set plans plan-id (merge plan { provider: new-provider }))
      (ok true)
    )
    (err u100)
  )
)

;; === Admin remove plan ===
(define-public (remove-plan (plan-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err u106))
    (map-delete plans plan-id)
    (ok true)
  )
)

;; === Admin remove subscription ===
(define-public (remove-subscription (subscriber principal) (plan-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err u106))
    (map-delete subscriptions { subscriber: subscriber, plan-id: plan-id })
    (ok true)
  )
)

;; === Read-only: Get plan ===
(define-read-only (get-plan (plan-id uint))
  (ok (map-get? plans plan-id))
)

;; === Read-only: Get subscription ===
(define-read-only (get-subscription (subscriber principal) (plan-id uint))
  (ok (map-get? subscriptions { subscriber: subscriber, plan-id: plan-id }))
)

;; === Admin transfer ===
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err u106))
    (var-set contract-admin new-admin)
    (ok true)
  )
)
