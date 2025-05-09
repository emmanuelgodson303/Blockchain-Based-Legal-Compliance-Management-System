;; Implementation Contract
;; Manages compliance activities for entities

(define-data-var admin principal tx-sender)

;; Map of compliance implementations
(define-map compliance-implementations
  {
    entity-id: (string-ascii 64),
    requirement-id: (string-ascii 64),
    implementation-id: (string-ascii 64)
  }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    implementation-date: uint,
    status: (string-ascii 20),
    responsible-party: principal
  }
)

;; Public function to record a compliance implementation
(define-public (record-implementation
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (implementation-id (string-ascii 64))
    (title (string-ascii 100))
    (description (string-utf8 500))
    (responsible-party principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? compliance-implementations
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        implementation-id: implementation-id
      })) (err u100))

    (map-set compliance-implementations
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        implementation-id: implementation-id
      }
      {
        title: title,
        description: description,
        implementation-date: block-height,
        status: "in-progress",
        responsible-party: responsible-party
      }
    )
    (ok true)
  )
)

;; Public function to update implementation status
(define-public (update-implementation-status
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (implementation-id (string-ascii 64))
    (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? compliance-implementations
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        implementation-id: implementation-id
      })) (err u404))

    (let ((implementation (unwrap-panic (map-get? compliance-implementations
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        implementation-id: implementation-id
      }))))
      (map-set compliance-implementations
        {
          entity-id: entity-id,
          requirement-id: requirement-id,
          implementation-id: implementation-id
        }
        (merge implementation { status: new-status })
      )
    )
    (ok true)
  )
)

;; Read-only function to get implementation details
(define-read-only (get-implementation-details
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (implementation-id (string-ascii 64)))
  (map-get? compliance-implementations
    {
      entity-id: entity-id,
      requirement-id: requirement-id,
      implementation-id: implementation-id
    }
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
