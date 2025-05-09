;; Documentation Contract
;; Records evidence of compliance

(define-data-var admin principal tx-sender)

;; Map of compliance documentation
(define-map compliance-documents
  {
    entity-id: (string-ascii 64),
    requirement-id: (string-ascii 64),
    document-id: (string-ascii 64)
  }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    document-hash: (buff 32),
    document-type: (string-ascii 50),
    submission-date: uint,
    submitted-by: principal,
    status: (string-ascii 20)
  }
)

;; Public function to submit a compliance document
(define-public (submit-document
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (document-id (string-ascii 64))
    (title (string-ascii 100))
    (description (string-utf8 500))
    (document-hash (buff 32))
    (document-type (string-ascii 50)))
  (begin
    (asserts! (is-none (map-get? compliance-documents
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        document-id: document-id
      })) (err u100))

    (map-set compliance-documents
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        document-id: document-id
      }
      {
        title: title,
        description: description,
        document-hash: document-hash,
        document-type: document-type,
        submission-date: block-height,
        submitted-by: tx-sender,
        status: "submitted"
      }
    )
    (ok true)
  )
)

;; Public function to verify a document (admin only)
(define-public (verify-document
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (document-id (string-ascii 64))
    (verification-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? compliance-documents
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        document-id: document-id
      })) (err u404))

    (let ((document (unwrap-panic (map-get? compliance-documents
      {
        entity-id: entity-id,
        requirement-id: requirement-id,
        document-id: document-id
      }))))
      (map-set compliance-documents
        {
          entity-id: entity-id,
          requirement-id: requirement-id,
          document-id: document-id
        }
        (merge document { status: verification-status })
      )
    )
    (ok true)
  )
)

;; Read-only function to get document details
(define-read-only (get-document-details
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (document-id (string-ascii 64)))
  (map-get? compliance-documents
    {
      entity-id: entity-id,
      requirement-id: requirement-id,
      document-id: document-id
    }
  )
)

;; Read-only function to verify document hash
(define-read-only (verify-document-hash
    (entity-id (string-ascii 64))
    (requirement-id (string-ascii 64))
    (document-id (string-ascii 64))
    (hash-to-verify (buff 32)))
  (let ((document (map-get? compliance-documents
    {
      entity-id: entity-id,
      requirement-id: requirement-id,
      document-id: document-id
    })))
    (if (is-some document)
      (is-eq (get document-hash (unwrap-panic document)) hash-to-verify)
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
