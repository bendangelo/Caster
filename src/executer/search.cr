module Executer
  class Search
    @@debug = [] of String
    def self.debug
      @@debug
    end

    def self.execute(store : Store::Item, token : Lexer::Token, limit : Int32, offset : Int32, greater_than : Tuple(UInt32, UInt32)? = nil, less_than : Tuple(UInt32, UInt32)? = nil, equal : Tuple(UInt32, UInt32)? = nil)

      # general_kv_access_lock_read!
      # general_fst_access_lock_read!
      bucket = store.bucket

      if bucket.nil?
        Log.error { "bucket is nil" }
        return [] of String
      end

      result_oids = Array(String).new limit

      kv_store = Store::KVPool.acquire(Store::KVAcquireMode::OpenOnly, store.collection)
      # StoreFSTPool.acquire(collection, bucket)
      # executor_kv_lock_read!(kv_store)

      kv_action = Store::KVAction.new(bucket: bucket, store: kv_store)
      # fst_action = StoreFSTActionBuilder.access(fst_store)

      found_iids = Hash(UInt32, Int32).new

      token.parse_text do |term, term_hashed, index|
        kv_action.iterate_term_to_iids(term_hashed, index, token.index_limit) do |iids, term_index|

          Log.debug { "got search executor iids: #{iids} for term: #{term}" }

          iids.each do |iid|
            if found_iids.has_key? iid
              found_iids[iid] += token.index_limit.to_i32 - term_index - index
            else
              found_iids[iid] = token.index_limit.to_i32 - term_index - index
            end
          end

        end

        # next if iids.nil?
        # higher_limit = APP_CONF.store.kv.retain_word_objects
        # alternates_try = APP_CONF.channel.search.query_alternates_try
        #
        # if iids.size < higher_limit && alternates_try > 0
        #   Log.debug { "not enough iids were found (#{iids.size}/#{higher_limit}), completing for term: #{term}" }
        #
        #   if suggested_words = fst_action.suggest_words(term, alternates_try + 1, 1)
        #     iids_new_len = iids.size
        #
        #     suggested_words.each do |suggested_word|
        #       next if suggested_word == term
        #
        #       Log.debug { "got completed word: #{suggested_word} for term: #{term}" }
        #
        #       if let Some(suggested_iids) = kv_action.get_term_to_iids(StoreTermHash.new(suggested_word)).unwrap_or(nil)
        #         suggested_iids.each do |suggested_iid|
        #           unless iids.include?(suggested_iid)
        #             iids << suggested_iid
        #             iids_new_len += 1
        #
        #             if iids_new_len >= higher_limit
        #               Log.debug { "got enough completed results for term: #{term}" }
        #               break
        #             end
        #           end
        #         end
        #       end
        #     end
        #
        #     Log.debug { "done completing results for term: #{term}, now #{iids_new_len} results" }
        #   else
        #     Log.debug { "did not get any completed word for term: #{term}" }
        #     end
        # end

        Log.debug { "got search executor iid intersection: #{found_iids} for term: #{term}" }
      end

      sorted_iids = found_iids.to_a.unstable_sort_by do |k, v|
        -v # in reverse
      end

      sorted_iids.each_with_index do |(iid, value), index|
        next if index < offset
        break if index >= limit + offset

        if oid = kv_action.get_iid_to_oid(iid)
          result_oids << oid
          # @@debug << "#{oid} #{-positions[iid].sum} #{positions[iid].size}"
        else
          Log.error { "failed getting search executor iid-to-oid" }
        end
      end

      Log.info { "got search executor final oids: #{result_oids}" }

      result_oids
    end
  end

end
