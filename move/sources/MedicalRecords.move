module MedicalRecords {
    struct Record has copy, drop, store {
        record_id: u64,
        timestamp: u64,
        name: vector<u8>,
        age: u64,
        gender: vector<u8>,
        blood_type: vector<u8>,
        allergies: vector<u8>,
        diagnosis: vector<u8>,
        treatment: vector<u8>,
    }

    resource struct RecordManager has key {
        records: vector<Record>,
        deleted_records: vector<bool>, // parallel array to indicate deleted records
        next_record_id: u64,
    }

    public fun init_module(owner: &signer) {
        let record_manager = RecordManager {
            records: vector::empty<Record>(),
            deleted_records: vector::empty<bool>(),
            next_record_id: 1,
        };
        move_to(owner, record_manager);
    }

    public fun add_record(
        owner: &signer,
        name: vector<u8>,
        age: u64,
        gender: vector<u8>,
        blood_type: vector<u8>,
        allergies: vector<u8>,
        diagnosis: vector<u8>,
        treatment: vector<u8>
    ) acquires RecordManager {
        let record_manager = borrow_global_mut<RecordManager>(signer::address_of(owner));
        
        let new_record = Record {
            record_id: record_manager.next_record_id,
            timestamp: Timestamp::now_seconds(),
            name: name,
            age: age,
            gender: gender,
            blood_type: blood_type,
            allergies: allergies,
            diagnosis: diagnosis,
            treatment: treatment,
        };

        vector::push_back(&mut record_manager.records, new_record);
        vector::push_back(&mut record_manager.deleted_records, false);
        record_manager.next_record_id = record_manager.next_record_id + 1;
    }

    public fun delete_record(
        owner: &signer,
        record_id: u64
    ) acquires RecordManager {
        let record_manager = borrow_global_mut<RecordManager>(signer::address_of(owner));
        
        let idx = find_record_index(&record_manager.records, record_id);
        assert!(!vector::borrow(&record_manager.deleted_records, idx), 1); // Record is already deleted
        vector::borrow_mut(&mut record_manager.deleted_records, idx) = true;
    }

    public fun get_record(
        owner: &signer,
        record_id: u64
    ): Record acquires RecordManager {
        let record_manager = borrow_global<RecordManager>(signer::address_of(owner));
        
        let idx = find_record_index(&record_manager.records, record_id);
        assert!(!vector::borrow(&record_manager.deleted_records, idx), 1); // Record is deleted
        *vector::borrow(&record_manager.records, idx)
    }

    public fun get_record_id(owner: &signer): u64 acquires RecordManager {
        let record_manager = borrow_global<RecordManager>(signer::address_of(owner));
        record_manager.next_record_id - 1
    }

    public fun is_deleted(owner: &signer, record_id: u64): bool acquires RecordManager {
        let record_manager = borrow_global<RecordManager>(signer::address_of(owner));
        
        let idx = find_record_index(&record_manager.records, record_id);
        *vector::borrow(&record_manager.deleted_records, idx)
    }

    fun find_record_index(records: &vector<Record>, record_id: u64): u64 {
        let len = vector::length(records);
        let mut i = 0;
        while (i < len) {
            if (vector::borrow(records, i).record_id == record_id) {
                return i;
            }
            i = i + 1;
        }
        abort 1; // Record not found
    }
}
