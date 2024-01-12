require "../spec_helper"

Spectator.describe Executer::Push do
  include Executer

  describe ".execute" do
    context "stores words in bucket for object" do

      let(text) { "hello world" }
      let(collection) { "col" }
      let(bucket) { "buck" }
      let(object) { "push_obj" }

      let(store) do
        Store::KVPool.acquire(Store::KVAcquireMode::Any, collection)
      end
      let(action) do
        Store::KVAction.new(bucket: bucket, store: store)
      end
      let(item) { Store::Item.new collection, bucket, object }
      let(token) { Lexar::Token.new Lexar::TokenMode::NormalizeOnly, text, Lexar::Lang::Eng }

      before do
        Push.execute item, token
      end

      it "associated oid to iid and iid to oid for object" do
        expect(action.get_oid_to_iid(object)).to eq 1
        expect(action.get_iid_to_oid(1)).to eq object
        expect(action.get_meta_to_value(Store::IIDIncr)).to eq 1
      end

      it "associates all terms to iid" do
        expect(action.get_iid_to_terms(1)).to eq Set.new UInt32[4211111929, 413819571]
      end

      it "associates iid to all terms" do
        expect(action.get_term_to_iids(Store::Hasher.to_compact("hello"))).to eq Set.new UInt32[1]
        expect(action.get_term_to_iids(Store::Hasher.to_compact("world"))).to eq Set.new UInt32[1]
      end

    end
  end
end
