module Executer
  class Push
    def self.execute(item : Store::Item, token : Lexar::Token)
      # general_kv_access_lock_read!
      # general_fst_access_lock_read!

      collection, bucket, object = item.collection, item.bucket, item.object

      if bucket.nil?
        Log.error { "bucket is nil" }
        return
      end
      if object.nil?
        Log.error { "object is nil" }
        return
      end

      # if let (Ok(kv_store), Ok(fst_store)) = (
      kv_store = Store::KVPool.acquire(Store::KVAcquireMode::Any, collection)
      #   StoreFSTPool.acquire(collection, bucket)
      # )
      # executor_kv_lock_write!(kv_store)

      kv_action = Store::KVAction.new(bucket: bucket, store: kv_store)
      # fst_action = StoreFSTActionBuilder.access(fst_store)

      # Try to resolve existing OID to IID, otherwise initialize IID (store the
      #   bi-directional relationship)
      oid = object
      iid = kv_action.get_oid_to_iid(oid) do |store_key|
        Log.info { "must initialize push executor oid-to-iid and iid-to-oid" }

        iid_incr = kv_action.get_meta_to_value(Store::IIDIncr)
        iid_incr = (iid_incr.nil? ? 0_u32 : iid_incr.to_u32) + 1

        kv_action.set_meta_to_value(Store::IIDIncr, iid_incr)
        kv_action.set_oid_to_iid(oid, iid_incr)
        kv_action.set_iid_to_oid(iid_incr, oid)

        iid_incr
      end

      # if iid.not_nil?
      #   has_commits = false
      #   iid_terms_hashed = LinkedHashSet(StoreTermHashed).new(
      #     kv_action.get_iid_to_terms(iid).unwrap_or(nil).unwrap_or(LinkedHashSet(StoreTermHashed).new)
      #   )
      #
      #   Log.info { "got push executor stored iid-to-terms: #{iid_terms_hashed}" }
      #
      #   token.each do |term, term_hashed|
      #     if !iid_terms_hashed.include?(term_hashed)
      #       if let Ok(term_iids) = kv_action.get_term_to_iids(term_hashed)
      #         has_commits = true
      #
      #         term_iids = term_iids.nil? ? [] : term_iids
      #
      #         if term_iids.include?(iid)
      #           term_iids.delete(iid)
      #         end
      #
      #         Log.info { "has push executor term-to-iids: #{iid}" }
      #
      #         term_iids.unshift(iid)
      #
      #         # truncate_limit = APP_CONF.store.kv.retain_word_objects
      #         #
      #         # if term_iids.size > truncate_limit
      #         #   Log.info { "push executor term-to-iids object too long (limit: #{truncate_limit})" }
      #         #   term_iids_drain = term_iids.pop(truncate_limit)
      #         #   executor_ensure_op!(kv_action.batch_truncate_object(term_hashed, term_iids_drain))
      #         # end
      #
      #         executor_ensure_op!(kv_action.set_term_to_iids(term_hashed, term_iids))
      #
      #         iid_terms_hashed << term_hashed
      #       else
      #         Log.error { "failed getting push executor term-to-iids" }
      #       end
      #     end
      #
      #     # if fst_action.push_word(term)
      #     #   Log.debug { "push term committed to graph: #{term}" }
      #     # end
      #   end
      #
      #   if has_commits
      #     collected_iids = iid_terms_hashed.to_a
      #
      #     Log.info { "has push executor iid-to-terms commits: #{collected_iids}" }
      #
      #     executor_ensure_op!(kv_action.set_iid_to_terms(iid, collected_iids))
      #   end
      #
      # end
    end

  end
end
