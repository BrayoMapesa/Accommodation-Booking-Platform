#[allow(lint(coin_field))]
module Accomodation_Booking::platform {
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::transfer::public_transfer;
    use sui::sui::SUI;
    use std::string::String;

    // Error codes
    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_INVALID_BOOKING_ID: u64 = 2;
    const ERROR_INVALID_ACCOMMODATION_ID: u64 = 3;
    const ERROR_ACCOMMODATION_NOT_AVAILABLE: u64 = 4;
    const ERROR_INSUFFICIENT_PAYMENT: u64 = 5;

    // Structs
    public struct Platform has key, store {
        id: UID, // Unique identifier for the platform
        balance: Coin<SUI>, // Keeping Coin<SUI> to avoid dependency cycle
        accommodations: vector<Accommodation>, // List of accommodations on the platform
        bookings: vector<Booking>, // List of bookings made on the platform
        reviews: vector<Review>, // List of reviews left on the platform
        special_offers: vector<SpecialOffer>, // List of special offers available on the platform
    }

    public struct Accommodation has store {
        id: u64, // Unique identifier for the accommodation
        owner: address, // Owner of the accommodation
        details: String, // Details about the accommodation
        price: u64, // Price per night for the accommodation
        available: bool, // Availability status of the accommodation
    }

    public struct Booking has store {
        id: u64, // Unique identifier for the booking
        accommodation_id: u64, // Identifier for the booked accommodation
        traveler: address, // Address of the traveler who made the booking
        check_in_date: u64, // Check-in date for the booking
        check_out_date: u64, // Check-out date for the booking
        paid: u64, // Amount paid for the booking
    }

    public struct Review has store {
        id: u64, // Unique identifier for the review
        accommodation_id: u64, // Identifier for the reviewed accommodation
        reviewer: address, // Address of the reviewer
        review: String, // Review text
        rating: u8, // Rating given by the reviewer
    }

    public struct SpecialOffer has store {
        id: u64, // Unique identifier for the special offer
        accommodation_id: u64, // Identifier for the accommodation with the special offer
        discount_percentage: u64, // Discount percentage of the special offer
        start_date: u64, // Start date of the special offer
        end_date: u64, // End date of the special offer
    }

    // Events
    public struct AccommodationListed has copy, drop {
        id: u64, // Identifier for the listed accommodation
        owner: address, // Owner of the listed accommodation
        details: String, // Details about the listed accommodation
        price: u64, // Price per night for the listed accommodation
    }

    public struct AccommodationBooked has copy, drop {
        booking_id: u64, // Identifier for the booking
        accommodation_id: u64, // Identifier for the booked accommodation
        traveler: address, // Address of the traveler who made the booking
        check_in_date: u64, // Check-in date for the booking
        check_out_date: u64, // Check-out date for the booking
        paid: u64, // Amount paid for the booking
    }

    public struct ReviewLeft has copy, drop {
        id: u64, // Identifier for the review
        accommodation_id: u64, // Identifier for the reviewed accommodation
        reviewer: address, // Address of the reviewer
        review: String, // Review text
        rating: u8, // Rating given by the reviewer
    }

    public struct BookingCanceled has copy, drop {
        booking_id: u64, // Identifier for the canceled booking
        refund_amount: u64, // Amount refunded for the canceled booking
    }

    // Functions
    /// Function to create the platform with initial zero balance
    public fun create_platform(ctx: &mut TxContext) {
        let platform = Platform {
            id: object::new(ctx),
            balance: coin::zero<SUI>(ctx), // Initialize with zero balance
            accommodations: vector::empty(),
            bookings: vector::empty(),
            reviews: vector::empty(),
            special_offers: vector::empty(),
        };
        transfer::public_share_object(platform); // Share the platform object publicly
    }

    /// Function to list a new accommodation on the platform
    public fun list_accommodation(
        platform: &mut Platform,
        owner: address,
        details: String,
        price: u64,
        _ctx: &mut TxContext
    ) {
        let id = vector::length(&platform.accommodations) as u64; // Generate a new ID for the accommodation
        let accommodation = Accommodation {
            id,
            owner,
            details,
            price,
            available: true,
        };
        vector::push_back(&mut platform.accommodations, accommodation); // Add the accommodation to the platform

        event::emit(AccommodationListed {
            id,
            owner,
            details,
            price,
        }); // Emit an event for the new accommodation listing
    }

    /// Function to book an accommodation
    public fun book_accommodation(
        platform: &mut Platform,
        accommodation_id: u64,
        traveler: address,
        check_in_date: u64,
        check_out_date: u64,
        mut payment_coin: Coin<SUI>, // Declare payment_coin as mutable
        ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
        let accommodation = vector::borrow_mut(&mut platform.accommodations, accommodation_id);
        assert!(accommodation.available, ERROR_ACCOMMODATION_NOT_AVAILABLE);
        
        let total_price = accommodation.price;
        assert!(coin::value(&payment_coin) >= total_price, ERROR_INSUFFICIENT_PAYMENT);

        // Use the payment coin directly, as it now matches the expected type
        let paid_coin: Coin<SUI> = coin::split(&mut payment_coin, total_price, ctx);
        coin::join(&mut platform.balance, payment_coin); // Update platform balance

        let booking_id = vector::length(&platform.bookings) as u64; // Generate a new ID for the booking
        let booking = Booking {
            id: booking_id,
            accommodation_id,
            traveler,
            check_in_date,
            check_out_date,
            paid: total_price,
        };
        vector::push_back(&mut platform.bookings, booking); // Add the booking to the platform

        accommodation.available = false; // Mark the accommodation as unavailable

        event::emit(AccommodationBooked {
            booking_id,
            accommodation_id,
            traveler,
            check_in_date,
            check_out_date,
            paid: total_price,
        }); // Emit an event for the new booking

        public_transfer(paid_coin, accommodation.owner); // Transfer the payment coin to the accommodation owner
    }

    /// Function to leave a review for an accommodation
    public fun leave_review(
        platform: &mut Platform,
        accommodation_id: u64,
        reviewer: address,
        review: String,
        rating: u8,
        _ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
        let review_id = vector::length(&platform.reviews) as u64; // Generate a new ID for the review
        let review_entry = Review {
            id: review_id,
            accommodation_id,
            reviewer,
            review,
            rating,
        };
        vector::push_back(&mut platform.reviews, review_entry); // Add the review to the platform

        event::emit(ReviewLeft {
            id: review_id,
            accommodation_id,
            reviewer,
            review,
            rating,
        }); // Emit an event for the new review
    }

    /// Function to cancel a booking and refund the traveler
    public fun cancel_booking(
        platform: &mut Platform,
        booking_id: u64,
        traveler: address,
        ctx: &mut TxContext
    ) {
        assert!(booking_id < vector::length(&platform.bookings) as u64, ERROR_INVALID_BOOKING_ID);
        let booking = vector::borrow(&platform.bookings, booking_id);
        assert!(booking.traveler == traveler, ERROR_NOT_OWNER);

        let refund_amount = booking.paid / 2; // Example: 50% refund
        let refund_coin: Coin<SUI> = coin::split(&mut platform.balance, refund_amount, ctx); // Split the refund amount from the platform balance
        public_transfer(refund_coin, traveler); // Transfer the refund coin to the traveler

        event::emit(BookingCanceled {
            booking_id,
            refund_amount,
        }); // Emit an event for the canceled booking
    }

    /// Function to update the details and price of an accommodation
    public fun update_accommodation(
        platform: &mut Platform,
        accommodation_id: u64,
        owner: address,
        new_details: String,
        new_price: u64,
        _ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
        let accommodation = vector::borrow_mut(&mut platform.accommodations, accommodation_id);
        assert!(accommodation.owner == owner, ERROR_NOT_OWNER);

        accommodation.details = new_details; // Update the details of the accommodation
        accommodation.price = new_price; // Update the price of the accommodation
    }

    /// Function to search for accommodations based on location
    public fun search_accommodation(
        platform: &Platform,
        location: String,
        _start_date: u64,
        _end_date: u64
    ): vector<Accommodation> {
        let mut results = vector::empty<Accommodation>();
        let len = vector::length(&platform.accommodations);

        let mut i = 0;
        while (i < len) {
            let accommodation = vector::borrow(&platform.accommodations, i);
            if (accommodation.details == location) { // Equality check for search
                let result_accommodation = Accommodation {
                    id: accommodation.id,
                    owner: accommodation.owner,
                    details: accommodation.details,
                    price: accommodation.price,
                    available: accommodation.available,
                };
                vector::push_back(&mut results, result_accommodation);
            };
            i = i + 1;
        };

        results // Return the search results
    }

    /// Function to check-in a traveler to an accommodation
    public fun check_in(
        platform: &mut Platform,
        booking_id: u64,
        traveler: address,
        ctx: &mut TxContext
    ) {
        assert!(booking_id < vector::length(&platform.bookings) as u64, ERROR_INVALID_BOOKING_ID);
        let booking = vector::borrow(&platform.bookings, booking_id);
        assert!(booking.traveler == traveler, ERROR_NOT_OWNER);

        let accommodation_id = booking.accommodation_id;
        let accommodation = vector::borrow_mut(&mut platform.accommodations, accommodation_id);

        let payment = coin::split(&mut platform.balance, booking.paid, ctx); // Split the payment amount from the platform balance
        public_transfer(payment, accommodation.owner); // Transfer the payment to the accommodation owner
    }

    /// Function to report an accommodation
    public fun report_accommodation(
        platform: &mut Platform,
        accommodation_id: u64,
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
    }

    /// Function to contact the host of an accommodation
    public fun contact_host(
        platform: &mut Platform,
        accommodation_id: u64,
        _message: String,
        _ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
        let _accommodation = vector::borrow(&platform.accommodations, accommodation_id);
        // Messaging logic to be handled off-chain or by administrators
    }

    /// Function to list special offers for an accommodation
    public fun list_special_offers(
        platform: &mut Platform,
        accommodation_id: u64,
        discount_percentage: u64,
        start_date: u64,
        end_date: u64,
        _ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
        let special_offer_id = vector::length(&platform.special_offers) as u64;
        let special_offer = SpecialOffer {
            id: special_offer_id,
            accommodation_id,
            discount_percentage,
            start_date,
            end_date,
        };
        vector::push_back(&mut platform.special_offers, special_offer);
    }

    /// Function to view the booking history of a traveler
    public fun view_booking_history(
        platform: &Platform,
        traveler: address
    ): vector<Booking> {
        let mut results = vector::empty<Booking>();
        let len = vector::length(&platform.bookings);

        let mut i = 0;
        while (i < len) {
            let booking = vector::borrow(&platform.bookings, i);
            if (booking.traveler == traveler) {
                let result_booking = Booking {
                    id: booking.id,
                    accommodation_id: booking.accommodation_id,
                    traveler: booking.traveler,
                    check_in_date: booking.check_in_date,
                    check_out_date: booking.check_out_date,
                    paid: booking.paid,
                };
                vector::push_back(&mut results, result_booking);
            };
            i = i + 1;
        };

        results // Return the booking history
    }

    /// Function to apply a cancellation policy to an accommodation
    public fun apply_cancellation_policy(
        platform: &mut Platform,
        accommodation_id: u64,
        _policy_id: u64,
        _ctx: &mut TxContext
    ) {
        assert!(accommodation_id < vector::length(&platform.accommodations) as u64, ERROR_INVALID_ACCOMMODATION_ID);
    }

    /// Getter for the platform details
    public fun get_platform_details(platform: &Platform): (&UID, &Coin<SUI>, &vector<Accommodation>, &vector<Booking>, &vector<Review>) {
        (
            &platform.id, 
            &platform.balance, 
            &platform.accommodations, 
            &platform.bookings, 
            &platform.reviews
        )
    }

    /// Getter for a specific booking
    public fun get_booking_details(platform: &Platform, booking_id: u64): (u64, u64, address, u64, u64, u64) {
        assert!(booking_id < vector::length(&platform.bookings) as u64, ERROR_INVALID_BOOKING_ID);
        let booking = vector::borrow(&platform.bookings, booking_id);
        (
            booking.id,
            booking.accommodation_id,
            booking.traveler,
            booking.check_in_date,
            booking.check_out_date,
            booking.paid
        )
    }

    /// Getter for a specific review
    public fun get_review_details(platform: &Platform, review_id: u64): (u64, u64, address, String, u8) {
        assert!(review_id < vector::length(&platform.reviews) as u64, ERROR_INVALID_BOOKING_ID);
        let review = vector::borrow(&platform.reviews, review_id);
        (
            review.id,
            review.accommodation_id,
            review.reviewer,
            review.review,
            review.rating
        )
    }

    /// Getter for a specific special offer
    public fun get_special_offer_details(platform: &Platform, special_offer_id: u64): (u64, u64, u64, u64, u64) {
        assert!(special_offer_id < vector::length(&platform.special_offers) as u64, ERROR_INVALID_BOOKING_ID);
        let special_offer = vector::borrow(&platform.special_offers, special_offer_id);
        (
            special_offer.id,
            special_offer.accommodation_id,
            special_offer.discount_percentage,
            special_offer.start_date,
            special_offer.end_date
        )
    }
}
