import 'package:flutter/material.dart';
import '../services/google_places_service.dart';
import '../utils/address_utils.dart';
import 'dart:async';

class AccurateLocationPickerWidget extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool isRequired;
  final Function(String address, double lat, double lng)? onLocationSelected;
  final IconData prefixIcon;
  final String? countryCode; // optional ISO code to filter autocomplete

  const AccurateLocationPickerWidget({
    super.key,
    required this.controller,
    this.labelText = 'Location',
    this.hintText = 'Search for a location',
    this.isRequired = false,
    this.onLocationSelected,
    this.prefixIcon = Icons.location_on,
    this.countryCode,
  });

  @override
  State<AccurateLocationPickerWidget> createState() =>
      _AccurateLocationPickerWidgetState();
}

class _AccurateLocationPickerWidgetState
    extends State<AccurateLocationPickerWidget> {
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query.length > 2) {
        _searchPlaces(query);
      } else {
        _clearSuggestions();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await GooglePlacesService.searchPlaces(
        query,
        countryCode: widget.countryCode,
      );
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      if (_focusNode.hasFocus && suggestions.isNotEmpty) {
        _showOverlay();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
      print('Error searching places: $e');
    }
  }

  void _clearSuggestions() {
    setState(() {
      _suggestions = [];
    });
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    title: Text(
                      suggestion.mainText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      suggestion.secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () => _selectPlace(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    setState(() {
      _isLoading = true;
    });

    _removeOverlay();
    _focusNode.unfocus();

    try {
      final placeDetails =
          await GooglePlacesService.getPlaceDetails(suggestion.placeId);

      if (placeDetails != null) {
        // Clean the address to remove location codes
        final cleanedAddress =
            AddressUtils.cleanAddress(placeDetails.formattedAddress);
        widget.controller.text = cleanedAddress;

        if (widget.onLocationSelected != null) {
          print('=== LOCATION PICKER CALLBACK ===');
          print('Selected address: "$cleanedAddress"');
          print('Selected latitude: ${placeDetails.latitude}');
          print('Selected longitude: ${placeDetails.longitude}');
          print('================================');

          widget.onLocationSelected!(
            cleanedAddress,
            placeDetails.latitude,
            placeDetails.longitude,
          );
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error getting location details'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icon(widget.prefixIcon),
          suffixIcon: _isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        _clearSuggestions();
                        _focusNode.unfocus();
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        validator: widget.isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
        onTap: () {
          if (_suggestions.isNotEmpty) {
            _showOverlay();
          }
        },
      ),
    );
  }
}
