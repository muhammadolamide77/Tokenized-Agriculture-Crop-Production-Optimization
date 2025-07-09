;; Farm Manager Verification Contract
;; Validates and manages agricultural farm managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_DATA (err u103))

;; Data structures
(define-map farm-managers
  { manager: principal }
  {
    verified: bool,
    registration-date: uint,
    farm-size: uint,
    location: (string-ascii 50),
    certification-level: uint
  }
)

(define-map manager-stats
  { manager: principal }
  {
    total-crops: uint,
    success-rate: uint,
    reputation-score: uint
  }
)

;; Public functions
(define-public (register-farm-manager (farm-size uint) (location (string-ascii 50)) (certification-level uint))
  (let ((manager tx-sender))
    (asserts! (> farm-size u0) ERR_INVALID_DATA)
    (asserts! (> certification-level u0) ERR_INVALID_DATA)
    (asserts! (is-none (map-get? farm-managers { manager: manager })) ERR_ALREADY_VERIFIED)

    (map-set farm-managers
      { manager: manager }
      {
        verified: false,
        registration-date: block-height,
        farm-size: farm-size,
        location: location,
        certification-level: certification-level
      }
    )

    (map-set manager-stats
      { manager: manager }
      {
        total-crops: u0,
        success-rate: u100,
        reputation-score: u50
      }
    )

    (ok true)
  )
)

(define-public (verify-manager (manager principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? farm-managers { manager: manager })) ERR_NOT_FOUND)

    (map-set farm-managers
      { manager: manager }
      (merge (unwrap-panic (map-get? farm-managers { manager: manager }))
             { verified: true })
    )

    (ok true)
  )
)

(define-public (update-reputation (manager principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-score u100) ERR_INVALID_DATA)

    (map-set manager-stats
      { manager: manager }
      (merge (unwrap-panic (map-get? manager-stats { manager: manager }))
             { reputation-score: new-score })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manager-info (manager principal))
  (map-get? farm-managers { manager: manager })
)

(define-read-only (get-manager-stats (manager principal))
  (map-get? manager-stats { manager: manager })
)

(define-read-only (is-verified-manager (manager principal))
  (match (map-get? farm-managers { manager: manager })
    manager-data (get verified manager-data)
    false
  )
)
