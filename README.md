# Accommodation Booking Platform on Sui Blockchain

## Introduction

The **Accommodation Booking Platform** is a decentralized application built on the Sui blockchain. This platform enables property owners to list their accommodations and allows travelers to book these properties using SUI tokens. With a focus on transparency, security, and efficiency, the platform leverages blockchain technology to offer a streamlined booking experience.

Through this platform, travelers can browse listed accommodations, book their stay, and leave reviews, while property owners have the opportunity to manage their listings and receive payments directly in SUI. Additionally, the platform includes features like special offers, cancellation policies, and event-driven booking management.

## Purpose and Community Benefit

The **Accommodation Booking Platform** aims to:

1. **Promote Transparency and Security**: By utilizing the Sui blockchain, the platform ensures that every transaction and booking event is traceable and immutable. This reduces the chances of fraud and enhances trust between property owners and travelers.

2. **Empower Local Communities**: Property owners around the world, especially in underserved regions, can now have equal access to a global marketplace without intermediaries taking a significant portion of their earnings. The platform encourages the growth of local tourism and empowers property owners to earn in a decentralized manner.

3. **Support the Sui Ecosystem**: As an application built on the Sui blockchain, this platform drives the adoption of SUI as a medium of exchange, enhancing its utility. The use of SUI for payments, reviews, and special offers demonstrates its potential beyond traditional finance, making SUI a valuable asset for both travelers and property owners.

4. **Sustainable Development and Inclusivity**: By reducing reliance on intermediaries and providing global access to a decentralized accommodation platform, the project aims to make travel and tourism more inclusive, affordable, and sustainable. The goal is to democratize the accommodation market, supporting a shared economy that benefits all participants.

5. **Contribute to a Better World**: With its transparent, decentralized nature, the platform promotes fair trade and economic opportunities globally. It aligns with the values of decentralization, ensuring that no single entity controls the marketplace. Property owners can list their accommodations without barriers, while travelers can explore a world of diverse, unique stays.

## Structs Overview

### 1. `Platform`
- Represents the main platform structure, containing:
  - `id`: Unique identifier.
  - `balance`: Platform's balance in `Coin<SUI>`.
  - `accommodations`: Vector of listed accommodations.
  - `bookings`: Vector of made bookings.
  - `reviews`: Vector of user reviews.
  - `special_offers`: Vector of special offers.

### 2. `Accommodation`
- Holds details of an accommodation, including:
  - `id`: Unique accommodation identifier.
  - `owner`: Address of the property owner.
  - `details`: Description of the property.
  - `price`: Price per night.
  - `available`: Availability status.

### 3. `Booking`
- Represents a booking made on the platform:
  - `id`: Unique booking identifier.
  - `accommodation_id`: Linked accommodation.
  - `traveler`: Address of the traveler.
  - `check_in_date` and `check_out_date`: Booking period.
  - `paid`: Amount paid.

### 4. `Review`
- Stores review data for an accommodation:
  - `id`: Unique review identifier.
  - `accommodation_id`: Linked accommodation.
  - `reviewer`: Address of the reviewer.
  - `review`: Text content.
  - `rating`: Rating out of 5.

### 5. `SpecialOffer`
- Details special offers for accommodations:
  - `id`: Unique special offer identifier.
  - `accommodation_id`: Linked accommodation.
  - `discount_percentage`: Discount offered.
  - `start_date` and `end_date`: Validity period.

## Platform Modules and Functions

### **1. Create Platform**
```move
fun create_platform(ctx: &mut TxContext)
```
- Initializes the platform with zero balance.
- Registers and publicly shares the platform object.

### **2. List Accommodation**
```move
fun list_accommodation(platform: &mut Platform, owner: address, details: String, price: u64, _ctx: &mut TxContext)
```
- Adds a new accommodation to the platform.
- Emits an `AccommodationListed` event.

### **3. Book Accommodation**
```move
fun book_accommodation(platform: &mut Platform, accommodation_id: u64, traveler: address, check_in_date: u64, check_out_date: u64, mut payment_coin: Coin<SUI>, ctx: &mut TxContext)
```
- Books an available accommodation by a traveler.
- Transfers the payment to the accommodation owner.
- Emits an `AccommodationBooked` event.

### **4. Leave Review**
```move
fun leave_review(platform: &mut Platform, accommodation_id: u64, reviewer: address, review: String, rating: u8, _ctx: &mut TxContext)
```
- Allows users to leave a review for a booked accommodation.
- Emits a `ReviewLeft` event.

### **5. Cancel Booking**
```move
fun cancel_booking(platform: &mut Platform, booking_id: u64, traveler: address, ctx: &mut TxContext)
```
- Cancels a booking and issues a 50% refund.
- Emits a `BookingCanceled` event.

### **6. Update Accommodation**
```move
fun update_accommodation(platform: &mut Platform, accommodation_id: u64, owner: address, new_details: String, new_price: u64, _ctx: &mut TxContext)
```
- Updates details and price of an accommodation by the owner.

### **7. Search Accommodations**
```move
fun search_accommodation(platform: &Platform, location: String, _start_date: u64, _end_date: u64): vector<Accommodation>
```
- Searches for accommodations based on location.

### **8. View Booking History**
```move
fun view_booking_history(platform: &Platform, traveler: address): vector<Booking>
```
- Retrieves the booking history of a traveler.

### **9. Getters**
- `get_platform_details`: Retrieves platform details.
- `get_booking_details`: Retrieves specific booking details.
- `get_review_details`: Retrieves specific review details.
- `get_special_offer_details`: Retrieves specific special offer details.

## Events

### **AccommodationListed**
- Triggered when a new accommodation is listed.

### **AccommodationBooked**
- Triggered when an accommodation is successfully booked.

### **ReviewLeft**
- Triggered when a review is left for an accommodation.

### **BookingCanceled**
- Triggered when a booking is canceled and refund is issued.

## Future Development

- Implement messaging and review validation.
- Introduce support for dynamic pricing based on demand.
- Add multi-chain support for cross-platform bookings.

## Prerequisites

- **Sui CLI** - Ensure that Sui is installed and configured.
- **Fastcrypto** - Set up a key pair for platform deployment.

## Deployment Steps

1. **Generate Key Pair**:
   ```bash
   $ cd fastcrypto/
   $ cargo run --bin ecvrf-cli keygen
   ```
2. **Deploy Contract**:
   ```bash
   $ sui client publish --gas-budget 50000000
   ```

## Contribution

We welcome community contributions to improve this project. Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.
