/// Why this file exists:
/// Implementation of GuestRepository contract.
/// Delegates SQL to GuestLocalDataSource; focuses on domain mapping and audit.
library;

import '../../../../core/errors/failure.dart';
import '../../domain/entities/guest.dart';
import '../../domain/entities/guest_contact.dart';
import '../../domain/repositories/guest_repository.dart';
import '../datasources/guest_local_datasource.dart';
import '../models/guest_model.dart';
import '../models/guest_contact_model.dart';

class GuestRepositoryImpl implements GuestRepository {
  final GuestLocalDataSource _dataSource;

  GuestRepositoryImpl(this._dataSource);

  @override
  Future<List<Guest>> getGuests(int accountId, {bool includeArchived = false}) async {
    try {
      final maps = await _dataSource.getGuests(accountId, includeArchived);
      final List<Guest> guests = [];
      for (final map in maps) {
        final guest = GuestModel.fromMap(map);
        final contactMaps = await _dataSource.getGuestContacts(guest.id!);
        final contacts = contactMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
        guests.add(guest.copyWith(contacts: contacts));
      }
      return guests;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_GUESTS_FAILED',
        message: 'حدث خطأ أثناء جلب قائمة الضيوف.',
      );
    }
  }

  @override
  Future<Guest?> getGuestById(int id) async {
    try {
      final map = await _dataSource.getGuestById(id);
      if (map == null) return null;
      final guest = GuestModel.fromMap(map);
      final contactMaps = await _dataSource.getGuestContacts(id);
      final contacts = contactMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
      return guest.copyWith(contacts: contacts);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_GUEST_BY_ID_FAILED',
        message: 'حدث خطأ أثناء جلب بيانات الضيف.',
      );
    }
  }

  @override
  Future<Guest?> getGuestByDocument(int accountId, String documentType, String documentNumber) async {
    try {
      final map = await _dataSource.getGuestByDocument(accountId, documentType, documentNumber);
      if (map == null) return null;
      final guest = GuestModel.fromMap(map);
      final contactMaps = await _dataSource.getGuestContacts(guest.id!);
      final contacts = contactMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
      return guest.copyWith(contacts: contacts);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_GUEST_BY_DOCUMENT_FAILED',
        message: 'حدث خطأ أثناء التحقق من وثيقة الضيف.',
      );
    }
  }

  @override
  Future<List<Guest>> searchGuests(int accountId, String query, {bool includeArchived = false}) async {
    if (query.trim().isEmpty) {
      return getGuests(accountId, includeArchived: includeArchived);
    }
    try {
      final maps = await _dataSource.searchGuests(accountId, query, includeArchived);
      final List<Guest> guests = [];
      for (final map in maps) {
        final guest = GuestModel.fromMap(map);
        final contactMaps = await _dataSource.getGuestContacts(guest.id!);
        final contacts = contactMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
        guests.add(guest.copyWith(contacts: contacts));
      }
      return guests;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'SEARCH_GUESTS_FAILED',
        message: 'حدث خطأ أثناء البحث عن الضيوف.',
      );
    }
  }

  @override
  Future<int> createGuest(Guest guest, int userId) async {
    try {
      final guestMap = GuestModel.toMap(guest);
      final contactMaps = guest.contacts.map((c) => GuestContactModel.toMap(c)).toList();
      return await _dataSource.createGuestWithContacts(guestMap, contactMaps);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CREATE_GUEST_FAILED',
        message: 'فشل إنشاء الضيف في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<void> updateGuest(Guest guest, int userId) async {
    if (guest.id == null) {
      throw const DatabaseFailure(
        code: 'UPDATE_GUEST_MISSING_ID',
        message: 'معرّف الضيف مفقود لتحديث البيانات (Guest ID is required for update)',
      );
    }
    try {
      final guestMap = GuestModel.toMap(guest);
      final contactMaps = guest.contacts.map((c) => GuestContactModel.toMap(c.copyWith(guestId: guest.id))).toList();
      await _dataSource.updateGuestWithContacts(guestMap, contactMaps, guest.id!);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'UPDATE_GUEST_FAILED',
        message: 'فشل تحديث بيانات الضيف.',
      );
    }
  }

  @override
  Future<void> archiveGuest(int id, int userId) async {
    try {
      final oldGuest = await getGuestById(id);
      if (oldGuest == null) return;
      final now = DateTime.now().toIso8601String();
      await _dataSource.archiveGuest(id, now);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'ARCHIVE_GUEST_FAILED',
        message: 'فشل أرشفة الضيف في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<void> unarchiveGuest(int id, int userId) async {
    try {
      final oldGuest = await getGuestById(id);
      if (oldGuest == null) return;
      final now = DateTime.now().toIso8601String();
      await _dataSource.unarchiveGuest(id, now);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'UNARCHIVE_GUEST_FAILED',
        message: 'فشل استعادة الضيف في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<List<GuestContact>> getGuestContacts(int guestId) async {
    try {
      final maps = await _dataSource.getGuestContacts(guestId);
      return maps.map((map) => GuestContactModel.fromMap(map)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_GUEST_CONTACTS_FAILED',
        message: 'فشل جلب اتصالات الضيف.',
      );
    }
  }

  @override
  Future<void> saveGuestContact(GuestContact contact) async {
    try {
      final map = GuestContactModel.toMap(contact);
      if (contact.id == null) {
        await _dataSource.insertGuestContact(map);
      } else {
        await _dataSource.updateGuestContact(map, contact.id!);
      }
    } catch (e) {
      throw const DatabaseFailure(
        code: 'SAVE_GUEST_CONTACT_FAILED',
        message: 'فشل حفظ اتصال الضيف.',
      );
    }
  }

  @override
  Future<void> deleteGuestContact(int contactId) async {
    try {
      await _dataSource.deleteGuestContact(contactId);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'DELETE_GUEST_CONTACT_FAILED',
        message: 'فشل حذف اتصال الضيف.',
      );
    }
  }
}
