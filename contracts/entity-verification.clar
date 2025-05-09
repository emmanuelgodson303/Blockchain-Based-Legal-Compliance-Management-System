;; Entity Verification Contract
;; Validates regulated businesses on the blockchain

(define-data-var admin principal tx-sender)

;; Map of verified entities
(define-map verified-entities
  { entity-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    registration-number: (string-ascii 50),
    jurisdiction: (string-ascii 50),
    status: (string-ascii 20),
    verification-date: uint
  }
)

;; Public function to verify a new entity
(define-public (verify-entity
    (entity-id (string-ascii 64))
    (name (string-ascii 100))
    (registration-number (string-ascii 50))
    (jurisdiction (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-entities { entity-id: entity-id })) (err u100))

    (map-set verified-entities
      { entity-id: entity-id }
      {
        name: name,
        registration-number: registration-number,
        jurisdiction: jurisdiction,
        status: "active",
        verification-date: block-height
      }
    )
    (ok true)
  )
)

;; Public function to update entity status
(define-public (update-entity-status
    (entity-id (string-ascii 64))
    (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-entities { entity-id: entity-id })) (err u404))

    (let ((entity (unwrap-panic (map-get? verified-entities { entity-id: entity-id }))))
      (map-set verified-entities
        { entity-id: entity-id }
        (merge entity { status: new-status })
      )
    )
    (ok true)
  )
)

;; Read-only function to check if an entity is verified
(define-read-only (is-entity-verified (entity-id (string-ascii 64)))
  (let ((entity (map-get? verified-entities { entity-id: entity-id })))
    (if (is-some entity)
      (let ((entity-data (unwrap-panic entity)))
        (is-eq (get status entity-data) "active")
      )
      false
    )
  )
)

;; Read-only function to get entity details
(define-read-only (get-entity-details (entity-id (string-ascii 64)))
  (map-get? verified-entities { entity-id: entity-id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
