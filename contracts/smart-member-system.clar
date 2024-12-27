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

