pragma solidity ^0.8.0;

contract Airbnb {
    struct Booking {
        address guest;
        uint256 roomId;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
    }

    struct Room {
        string name;
        uint256 pricePerDay;
        bool available;
    }

    mapping(uint256 => Room) public rooms;
    mapping(uint256 => Booking) public bookings;
    uint256 public nextRoomId;
    uint256 public nextBookingId;
    
    event RoomAdded(uint256 roomId, string name, uint256 pricePerDay);
    event BookingCreated(uint256 bookingId, uint256 roomId, address guest, uint256 startDate, uint256 endDate);
    event BookingCanceled(uint256 bookingId);
    
    modifier roomExists(uint256 roomId) {
        require(roomId < nextRoomId, "Room does not exist.");
        _;
    }
    
    modifier roomAvailable(uint256 roomId) {
        require(rooms[roomId].available, "Room is not available.");
        _;
    }
    
    modifier bookingExists(uint256 bookingId) {
        require(bookingId < nextBookingId, "Booking does not exist.");
        _;
    }
    
    modifier onlyGuest(uint256 bookingId) {
        require(msg.sender == bookings[bookingId].guest, "Only the guest can perform this action.");
        _;
    }
    
    constructor() {
        nextRoomId = 1;
        nextBookingId = 1;
    }
    
    function addRoom(string memory name, uint256 pricePerDay) external {
        rooms[nextRoomId] = Room(name, pricePerDay, true);
        emit RoomAdded(nextRoomId, name, pricePerDay);
        nextRoomId++;
    }
    
    function bookRoom(uint256 roomId, uint256 startDate, uint256 endDate) external payable roomExists(roomId) roomAvailable(roomId) {
        require(startDate < endDate, "Invalid booking dates.");
        require(msg.value >= rooms[roomId].pricePerDay * (endDate - startDate + 1), "Insufficient funds to book the room.");

        bookings[nextBookingId] = Booking(msg.sender, roomId, startDate, endDate, true);
        rooms[roomId].available = false;
        emit BookingCreated(nextBookingId, roomId, msg.sender, startDate, endDate);
        nextBookingId++;
    }
    
    function cancelBooking(uint256 bookingId) external bookingExists(bookingId) onlyGuest(bookingId) {
        Booking storage booking = bookings[bookingId];
        require(booking.isActive, "Booking is already canceled.");

        rooms[booking.roomId].available = true;
        booking.isActive = false;

        payable(msg.sender).transfer(rooms[booking.roomId].pricePerDay * (booking.endDate - booking.startDate + 1));
        emit BookingCanceled(bookingId);
    }
    
    function getRoom(uint256 roomId) external view roomExists(roomId) returns (string memory, uint256, bool) {
        Room storage room = rooms[roomId];
        return (room.name, room.pricePerDay, room.available);
    }
    
    function getBooking(uint256 bookingId) external view bookingExists(bookingId) returns (address, uint256, uint256, uint256, bool) {
        Booking storage booking = bookings[bookingId];
        return (booking.guest, booking.roomId, booking.startDate, booking.endDate, booking.isActive);
    }
}
