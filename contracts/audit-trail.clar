;; Audit Trail Contract
;; Maintains immutable record of compliance activities

(define-data-var admin principal tx-sender)
(define-data-var event-counter uint u0)

;; Map of audit events
(define-map audit-events
  { event-id: uint }
  {
    entity-id: (string-ascii 64),
    event-type: (string-ascii 50),
    related-id: (string-ascii 64),
    description: (string-utf8 500),
    timestamp: uint,
    performed-by: principal
  }
)

;; Public function to record an audit event
(define-public (record-event
    (entity-id (string-ascii 64))
    (event-type (string-ascii 50))
    (related-id (string-ascii 64))
    (description (string-utf8 500)))
  (let ((new-event-id (+ (var-get event-counter) u1)))
    (begin
      (var-set event-counter new-event-id)

      (map-set audit-events
        { event-id: new-event-id }
        {
          entity-id: entity-id,
          event-type: event-type,
          related-id: related-id,
          description: description,
          timestamp: block-height,
          performed-by: tx-sender
        }
      )
      (ok new-event-id)
    )
  )
)

;; Read-only function to get event details
(define-read-only (get-event-details (event-id uint))
  (map-get? audit-events { event-id: event-id })
)

;; Read-only function to get the current event counter
(define-read-only (get-event-count)
  (var-get event-counter)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
