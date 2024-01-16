require "../../spec_helper"

Spectator.describe Pipe::IngestCommand do
  include Pipe

  describe ".dispatch_count" do

    subject(count) { Pipe::IngestCommand.dispatch_count parts }

    provided parts: "collection bucket object LANG eng -- text eng" do
      expect(count.type).to eq ResponseType::Err
    end

    provided parts: "collection bucket object" do
      expect(count.type).to eq ResponseType::Result
    end

    provided parts: "collection bucket object" do
      expect(count.type).to eq ResponseType::Result
    end

    provided parts: "collection bucket object" do
      expect(count.type).to eq ResponseType::Result
    end

  end

  describe ".dispatch_push" do

    subject(ingest) { Pipe::IngestCommand.dispatch_push parts }

    provided parts: %({"collection": "collection", "bucket": "bucket", "object": "object", "text": "testing"}) do
      expect(ingest).to eq CommandResult.ok
    end

    provided parts: %({"collection": "collection", "bucket": "bucket", "object": "object", "text": "testing", "keywords": ["hey", "wa"]}) do
      expect(ingest).to eq CommandResult.ok
    end

    context "invalid parts" do
      provided parts: "" do
        expect(ingest.type).to eq ResponseType::Err
      end

      provided parts: "collection" do
        expect(ingest.type).to eq ResponseType::Err
      end

      provided parts: "collection bucket" do
        expect(ingest.type).to eq ResponseType::Err
      end

      provided parts: "collection bucket obj" do
        expect(ingest.type).to eq ResponseType::Err
      end

      provided parts: "collection bucket obj -- " do
        expect(ingest.type).to eq ResponseType::Err
      end
    end

  end
end
