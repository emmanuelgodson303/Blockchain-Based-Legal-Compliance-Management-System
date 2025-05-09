;; Requirement Tracking Contract
;; Records applicable legal obligations for entities

(define-data-var admin principal tx-sender)

;; Map of legal requirements
(define-map legal-requirements
  { requirement-id: (string-ascii 64) }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    jurisdiction: (string-ascii 50),
    category: (string-ascii 50),
    effective-date: uint,
    expiry-date: (optional uint)
  }
)

;; Map of entity requirements (which requirements apply to which entities)
(define-map entity-requirements
  {
    entity-id: (string-ascii 64),
    requirement-id: (string-ascii 64)
  }
  {
    assigned-date: uint,
    status: (string-ascii 20)
  }
)

;; Public function to add a new legal requirement
(define-public (add-requirement
    (requirement-id (string-ascii 64))
    (title (string-ascii 100))
    (description (string-utf8 500))
    (jurisdiction (string-ascii 50))
    (category (string-ascii 50))
    (effective-date uint)
    (expiry-date (optional uint)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? legal-requirements { requirement-id: requirement-id })) (err u100))

    (map-set legal-requirements
      { requirement-id: requirement-id }
      {
        title: title,
        description: description,
        jurisdiction: jurisdiction,
        category: category,
        effective-date: effective-date,
        expiry-date: expiry-date
      }
    )
    (ok true)
  )
)

;; Public function to assign a requirement to an entity
(define-public (assign-requirement
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? legal-requirements { requirement-id: requirement-id })) (err u404))

    (map-set entity-requirements
      {
        entity-id: entity-id,
        requirement-id: requirement-id
      }
      {
        assigned-date: block-height,
        status: "pending"
      }
    )
    (ok true)
  )
)

;; Public function to update requirement status for an entity
(define-public (update-requirement-status
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? entity-requirements { entity-id: entity-id, requirement-id: requirement-id })) (err u404))

    (map-set entity-requirements
      {
        entity-id: entity-id,
        requirement-id: requirement-id
      }
      {
        assigned-date: (get assigned-date (unwrap-panic (map-get? entity-requirements { entity-id: entity-id, requirement-id: requirement-id }))),
        status: new-status
      }
    )
    (ok true)
  )
)

;; Read-only function to get requirement details
(define-read-only (get-requirement-details (requirement-id (string-ascii 64)))
  (map-get? legal-requirements { requirement-id: requirement-id })
)

;; Read-only function to get entity requirement status
(define-read-only (get-entity-requirement-status (entity-id (string-ascii 64)) (requirement-id (string-ascii 64)))
  (map-get? entity-requirements { entity-id: entity-id, requirement-id: requirement-id })
)

;; Read-only function to check if a requirement is active
(define-read-only (is-requirement-active (requirement-id (string-ascii 64)))
  (let ((req (map-get? legal-requirements { requirement-id: requirement-id })))
    (if (is-some req)
      (let ((req-data (unwrap-panic req)))
        (and
          (>= block-height (get effective-date req-data))
          (match (get expiry-date req-data)
            expiry (< block-height expiry)
            true
          )
        )
      )
      false
    )
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
