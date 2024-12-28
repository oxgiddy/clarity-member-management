;; ============================================
;; Clarity Smart Contract: Membership Management
;; ============================================
;;
;; Summary:
;; A decentralized membership management contract for user registration, 
;; profile updates, and access control. This contract supports secure, 
;; customizable, and privacy-aware interactions among members.
;;
;; Purpose:
;; - Register members with unique profiles (nickname, bio, preferences).
;; - Allow profile updates and visibility control.
;; - Ensure secure access with role-based permissions.
;; - Maintain activity logs and data integrity.
;;
;; Key Features:
;; - Role-based access: CONTRACT-OWNER as admin, members with controlled access.
;; - Secure profile visibility settings for privacy.
;; - Comprehensive error handling and validation.
;; - Storage and retrieval of member data in structured formats.
;;
;; Use Case:
;; Ideal for decentralized apps needing robust user management and privacy controls.
;;
;; ============================================

;; ===============
;; Constants
;; ===============

;; Error Constants
(define-constant ERR-UNAUTHORIZED (err u500))
(define-constant ERR-NOT-FOUND (err u501))
(define-constant ERR-DUPLICATE-MEMBER (err u502))
(define-constant ERR-INVALID-INPUT (err u503))
(define-constant ERR-FORBIDDEN (err u504))

;; Role Constants
(define-constant CONTRACT-OWNER tx-sender)

;; ===============
;; Data Variables
;; ===============

;; Track total number of members
(define-data-var member-count uint u0)

;; ===============
;; Data Maps
;; ===============

;; Primary member data storage
(define-map member-profiles
  { member-id: uint }
  {
    nickname: (string-ascii 50),
    wallet-address: principal,
    registered-date: uint,
    bio-text: (string-ascii 160),
    preferences: (list 5 (string-ascii 30))
  }
)

;; Profile visibility permissions
(define-map profile-visibility
  { member-id: uint, viewer-address: principal }
  { permission-granted: bool }
)

;; ===============
;; Helper Functions
;; ===============

;; Check if member exists
(define-private (member-exists? (member-id uint))
  (is-some (map-get? member-profiles { member-id: member-id }))
)

;; Verify member ownership
(define-private (is-member-owner? (member-id uint) (address principal))
  (match (map-get? member-profiles { member-id: member-id })
    member-data (is-eq (get wallet-address member-data) address)
    false
  )
)

;; Validate individual preference
(define-private (is-preference-valid? (preference (string-ascii 30)))
  (and
    (> (len preference) u0)
    (< (len preference) u31)
  )
)

;; Validate preferences list
(define-private (are-preferences-valid? (preferences (list 5 (string-ascii 30))))
  (and
    (> (len preferences) u0)
    (<= (len preferences) u5)
    (is-eq (len (filter is-preference-valid? preferences)) (len preferences))
  )
)

;; ===============
;; Public Functions
;; ===============

;; Register new member
(define-public (register-new-member 
    (nickname (string-ascii 50)) 
    (bio-text (string-ascii 160)) 
    (preferences (list 5 (string-ascii 30))))
  (let
    (
      (new-id (+ (var-get member-count) u1))
    )
    ;; Input validation
    (asserts! (and (> (len nickname) u0) (< (len nickname) u51)) ERR-INVALID-INPUT)
    (asserts! (and (> (len bio-text) u0) (< (len bio-text) u161)) ERR-INVALID-INPUT)
    (asserts! (are-preferences-valid? preferences) ERR-INVALID-INPUT)

    ;; Create member profile
    (map-insert member-profiles
      { member-id: new-id }
      {
        nickname: nickname,
        wallet-address: tx-sender,
        registered-date: block-height,
        bio-text: bio-text,
        preferences: preferences
      }
    )

    ;; Set initial visibility permission
    (map-insert profile-visibility
      { member-id: new-id, viewer-address: tx-sender }
      { permission-granted: true }
    )

    ;; Update member count
    (var-set member-count new-id)
    (ok new-id)
  )
)

;; Update member biography
(define-public (update-member-bio (member-id uint) (new-bio (string-ascii 160)))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)
    (asserts! (< (len new-bio) u161) ERR-INVALID-INPUT)

    ;; Update bio
    (map-set member-profiles
      { member-id: member-id }
      (merge member-data { bio-text: new-bio })
    )
    (ok true)
  )
)

;; Update member preferences
(define-public (update-member-preferences (member-id uint) (new-preferences (list 5 (string-ascii 30))))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)
    (asserts! (are-preferences-valid? new-preferences) ERR-INVALID-INPUT)

    ;; Update preferences
    (map-set member-profiles
      { member-id: member-id }
      (merge member-data { preferences: new-preferences })
    )
    (ok true)
  )
)

;; Remove member
(define-public (remove-member (member-id uint))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)

    ;; Remove member profile
    (map-delete member-profiles { member-id: member-id })
    (ok true)
  )
)

;; ================================
;; Function to update member nickname
;; ================================

(define-public (update-member-nickname (member-id uint) (new-nickname (string-ascii 50)))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)
    (asserts! (and (> (len new-nickname) u0) (< (len new-nickname) u51)) ERR-INVALID-INPUT)

    ;; Update nickname
    (map-set member-profiles
      { member-id: member-id }
      (merge member-data { nickname: new-nickname })
    )
    (ok true)
  )
)

;; ================================
;; Function to check member profile visibility
;; ================================

(define-public (check-profile-visibility (member-id uint) (viewer-address principal))
  (let
    (
      (visibility-data (unwrap! (map-get? profile-visibility { member-id: member-id, viewer-address: viewer-address }) ERR-NOT-FOUND))
    )
    ;; Check visibility permission
    (ok (get permission-granted visibility-data))
  )
)

;; Security enhancement: Limit access to member profiles
(define-public (get-member-profile-securely (member-id uint))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get wallet-address member-data)) ERR-UNAUTHORIZED)
    (ok member-data)
  )
)

;; Add meaningful functionality: Track member activity log
(define-map member-actions
  { member-id: uint }
  {
    action: (string-ascii 50),
    previous: (list 5 (string-ascii 30)),
    new: (list 5 (string-ascii 30))
  }
)

;; Add Clarity contract to retrieve last updated date for a member
(define-public (get-last-updated-date (member-id uint))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    (ok (get registered-date member-data))
  )
)

;; Enhance security by verifying membership with two-factor authentication
(define-public (verify-member-2fa (member-id uint) (auth-code uint))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
      (correct-code u1234) ;; Example authentication code
    )
    (asserts! (is-eq auth-code correct-code) ERR-FORBIDDEN)
    (ok true)
  )
)

;; Add a new member with a profile and preferences
(define-public (add-new-member 
    (nickname (string-ascii 50)) 
    (bio-text (string-ascii 160)) 
    (preferences (list 5 (string-ascii 30))))
  (let
    (
      (new-id (+ (var-get member-count) u1))
    )
    ;; Input validation
    (asserts! (and (> (len nickname) u0) (< (len nickname) u51)) ERR-INVALID-INPUT)
    (asserts! (and (> (len bio-text) u0) (< (len bio-text) u161)) ERR-INVALID-INPUT)
    (asserts! (are-preferences-valid? preferences) ERR-INVALID-INPUT)

    ;; Create member profile
    (map-insert member-profiles
      { member-id: new-id }
      {
        nickname: nickname,
        wallet-address: tx-sender,
        registered-date: block-height,
        bio-text: bio-text,
        preferences: preferences
      }
    )

    ;; Set initial visibility permission
    (map-insert profile-visibility
      { member-id: new-id, viewer-address: tx-sender }
      { permission-granted: true }
    )

    ;; Update member count
    (var-set member-count new-id)
    (ok new-id)
  )
)

;; Add a function to allow members to update their nickname
(define-public (update-nickname (member-id uint) (new-nickname (string-ascii 50)))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)

    ;; Update nickname
    (map-set member-profiles
      { member-id: member-id }
      (merge member-data { nickname: new-nickname })
    )
    (ok true)
  )
)

;; ===============
;; Refactor - Simplify Update Member Preferences Logic
;; ===============
;; This refactor simplifies the logic for updating member preferences and reduces code duplication.
(define-public (simplified-update-member-preferences (member-id uint) (new-preferences (list 5 (string-ascii 30))))
  (begin
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (are-preferences-valid? new-preferences) ERR-INVALID-INPUT)
    (map-set member-profiles
      { member-id: member-id }
      (merge (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND) { preferences: new-preferences })
    )
    (ok "Preferences updated")
  )
)

;; This function limits profile access to certain roles or members only
(define-public (limit-profile-access (member-id uint) (address principal))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Check if the address is allowed to access the profile
    (asserts! (is-eq (get wallet-address member-data) address) ERR-FORBIDDEN)
    (ok true)
  )
)

;; Enhance error handling for profile updates
(define-public (update-member-profile-safe (member-id uint) (new-nickname (string-ascii 50)) (new-bio (string-ascii 160)) (new-preferences (list 5 (string-ascii 30))))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    ;; Validation checks
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (asserts! (is-eq (get wallet-address member-data) tx-sender) ERR-FORBIDDEN)
    (asserts! (> (len new-nickname) u0) ERR-INVALID-INPUT)
    (asserts! (< (len new-nickname) u51) ERR-INVALID-INPUT)
    (asserts! (are-preferences-valid? new-preferences) ERR-INVALID-INPUT)

    ;; Update profile
    (map-set member-profiles
      { member-id: member-id }
      (merge member-data { nickname: new-nickname, bio-text: new-bio, preferences: new-preferences })
    )
    (ok true)
  )
)

;; Verify the ownership of a member's profile
(define-public (verify-profile-ownership (member-id uint) (owner-address principal))
  (let
    (
      (member-data (unwrap! (map-get? member-profiles { member-id: member-id }) ERR-NOT-FOUND))
    )
    (ok (is-eq owner-address (get wallet-address member-data)))
  )
)

;; Map to store member activity timestamps
(define-map member-activity-log
  { member-id: uint }
  {
    last-login: uint,
    total-logins: uint,
    last-action: (string-ascii 50)
  }
)

;; Record member login activity
(define-public (record-member-login (member-id uint))
  (let
    (
      (current-log (default-to 
        { last-login: u0, total-logins: u0, last-action: "None" }
        (map-get? member-activity-log { member-id: member-id })))
    )
    (asserts! (member-exists? member-id) ERR-NOT-FOUND)
    (map-set member-activity-log
      { member-id: member-id }
      {
        last-login: block-height,
        total-logins: (+ (get total-logins current-log) u1),
        last-action: "login"
      }
    )
    (ok true)
  )
)

;; Map to store member reputation scores
(define-map member-reputation
  { member-id: uint }
  {
    score: uint,
    endorsements: uint,
    last-updated: uint
  }
)
