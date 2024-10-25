;; Gaming Asset Contract
;; This contract manages in-game assets including creation, trading, and ownership

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ASSET-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-PRICE (err u103))
(define-constant ERR-ALREADY-LISTED (err u104))
(define-constant ERR-NOT-LISTED (err u105))

;; Data Variables
(define-map assets 
    { asset-id: uint }
    {
        owner: principal,
        metadata: (string-ascii 256),
        created-at: uint,
        transferable: bool
    }
)

(define-map asset-marketplace
    { asset-id: uint }
    {
        price: uint,
        seller: principal,
        listed: bool
    }
)

(define-map user-assets
    { owner: principal }
    { asset-count: uint }
)

;; Administrative Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-asset-id uint u1)
(define-data-var platform-fee uint u25) ;; 2.5% fee in basis points

;; Read-only functions
(define-read-only (get-asset (asset-id uint))
    (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-listing (asset-id uint))
    (map-get? asset-marketplace { asset-id: asset-id })
)

(define-read-only (get-user-assets (user principal))
    (default-to { asset-count: u0 }
        (map-get? user-assets { owner: user })
    )
)

(define-read-only (get-owner (asset-id uint))
    (let ((asset-data (get-asset asset-id)))
        (match asset-data
            asset-info (ok (get owner asset-info))
            (err ERR-ASSET-NOT-FOUND)
        )
    )
)

;; Private functions
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

(define-private (calculate-fee (price uint))
    (/ (* price (var-get platform-fee)) u1000)
)

;; Public functions
(define-public (create-asset (metadata (string-ascii 256)) (transferable bool))
    (let 
        (
            (asset-id (var-get next-asset-id))
            (current-count (get asset-count (get-user-assets tx-sender)))
        )
        (map-set assets
            { asset-id: asset-id }
            {
                owner: tx-sender,
                metadata: metadata,
                created-at: block-height,
                transferable: transferable
            }
        )
        (map-set user-assets
            { owner: tx-sender }
            { asset-count: (+ current-count u1) }
        )
        (var-set next-asset-id (+ asset-id u1))
        (ok asset-id)
    )
)

(define-public (transfer-asset (asset-id uint) (recipient principal))
    (let ((asset-info (get-asset asset-id)))
        (match asset-info
            current-asset (if (and
                    (is-eq (get owner current-asset) tx-sender)
                    (get transferable current-asset)
                )
                (begin
                    (map-set assets
                        { asset-id: asset-id }
                        (merge current-asset { owner: recipient })
                    )
                    (ok true)
                )
                ERR-NOT-AUTHORIZED
            )
            ERR-ASSET-NOT-FOUND
        )
    )
)

(define-public (list-asset (asset-id uint) (price uint))
    (let ((asset-info (get-asset asset-id)))
        (match asset-info
            current-asset 
            (if (and
                (is-eq (get owner current-asset) tx-sender)
                (> price u0)
            )
                (begin
                    (map-set asset-marketplace
                        { asset-id: asset-id }
                        {
                            price: price,
                            seller: tx-sender,
                            listed: true
                        }
                    )
                    (ok true)
                )
                ERR-INVALID-PRICE
            )
            ERR-ASSET-NOT-FOUND
        )
    )
)

(define-public (unlist-asset (asset-id uint))
    (let ((listing-info (get-listing asset-id)))
        (match listing-info
            current-listing
            (if (is-eq (get seller current-listing) tx-sender)
                (begin
                    (map-delete asset-marketplace { asset-id: asset-id })
                    (ok true)
                )
                ERR-NOT-AUTHORIZED
            )
            ERR-NOT-LISTED
        )
    )
)

(define-public (buy-asset (asset-id uint))
    (let (
        (listing-info (get-listing asset-id))
        (asset-info (get-asset asset-id))
    )
        (match listing-info
            current-listing
            (match asset-info
                current-asset
                (if (and
                    (get listed current-listing)
                    (is-eq (get owner current-asset) (get seller current-listing))
                )
                    (let (
                        (price (get price current-listing))
                        (seller (get seller current-listing))
                        (fee (calculate-fee price))
                        (seller-amount (- price fee))
                    )
                        (begin
                            ;; Transfer STX to seller
                            (try! (stx-transfer? seller-amount tx-sender seller))
                            ;; Transfer fee to contract owner
                            (try! (stx-transfer? fee tx-sender (var-get contract-owner)))
                            ;; Transfer asset ownership
                            (map-set assets
                                { asset-id: asset-id }
                                (merge current-asset { owner: tx-sender })
                            )
                            ;; Remove marketplace listing
                            (map-delete asset-marketplace { asset-id: asset-id })
                            (ok true)
                        )
                    )
                    ERR-NOT-LISTED
                )
                ERR-ASSET-NOT-FOUND
            )
            ERR-NOT-LISTED
        )
    )
)

;; Administrative functions
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-fee u1000) ERR-INVALID-PRICE)
        (var-set platform-fee new-fee)
        (ok true)
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)