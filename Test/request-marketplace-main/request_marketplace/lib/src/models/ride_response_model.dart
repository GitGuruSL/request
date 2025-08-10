import 'response_model.dart';
import 'driver_model.dart';

class RideResponseModel extends ResponseModel {
  final DriverModel? driverProfile;

  RideResponseModel({
    required super.id,
    required super.requestId,
    required super.responderId,
    required super.message,
    super.sharedPhoneNumbers = const [],
    super.offeredPrice,
    required super.createdAt,
    super.status = 'pending',
    super.responder,
    super.hasExpiry = false,
    super.expiryDate,
    super.deliveryAvailable = false,
    super.deliveryAmount,
    super.warranty,
    super.images = const [],
    super.location,
    super.latitude,
    super.longitude,
    this.driverProfile,
  });

  factory RideResponseModel.fromResponseModel(
    ResponseModel response,
    DriverModel? driverProfile,
  ) {
    return RideResponseModel(
      id: response.id,
      requestId: response.requestId,
      responderId: response.responderId,
      message: response.message,
      sharedPhoneNumbers: response.sharedPhoneNumbers,
      offeredPrice: response.offeredPrice,
      createdAt: response.createdAt,
      status: response.status,
      responder: response.responder,
      hasExpiry: response.hasExpiry,
      expiryDate: response.expiryDate,
      deliveryAvailable: response.deliveryAvailable,
      deliveryAmount: response.deliveryAmount,
      warranty: response.warranty,
      images: response.images,
      location: response.location,
      latitude: response.latitude,
      longitude: response.longitude,
      driverProfile: driverProfile,
    );
  }
}
