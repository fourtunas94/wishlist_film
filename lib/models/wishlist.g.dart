// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShareableWishlistAdapter extends TypeAdapter<ShareableWishlist> {
  @override
  final int typeId = 2;

  @override
  ShareableWishlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShareableWishlist(
      id: fields[0] as String,
      name: fields[1] as String,
      movies: (fields[2] as List).cast<Movie>(),
    );
  }

  @override
  void write(BinaryWriter writer, ShareableWishlist obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.movies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareableWishlistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
