module Caster
  class Settings
    include YAML::Serializable
    @@settings_path = "./src/config/settings.yml"

    def self.load_from_env!(silent = false)
      if env_pass = ENV["CASTER_PASSWORD"]?
        Caster.settings.auth_password = env_pass
        Log.info { "Password set from env var" } if !silent
      elsif Caster.settings.auth_password.blank?
        Log.warn { "No password set" } if !silent
      else
        Log.info { "Password set from settings path" } if !silent
      end
    end

    def self.settings_path
      if config = ENV["CASTER_CONFIG"]?
        config
      else
        @@settings_path
      end
    end

    def self.settings_path=(value)
        @@settings_path = value
    end

    property log_level : String
    property colorize : Bool

    property inet : String
    property port : Int32
    property tcp_timeout : Int32 = 300

    property auth_password : String = ""

    property search : SearchSettings
    property kv : KVSettings
  end

  class KVSettings
    include YAML::Serializable

    property path : String
    property pool : PoolSettings
    property database : DatabaseSettings
  end

  class PoolSettings
    include YAML::Serializable

    property inactive_after : Int32
  end

  class DatabaseSettings
    include YAML::Serializable

    property flush_after : Int32
    property compress : Bool # not implemented
    property parallelism : Int32
    property max_files : Int32 = -1
    property max_compactions : Int32
    property max_flushes : Int32
    property write_buffer : Int32
    property write_ahead_log : Bool
    property target_file_size_base : Int32
  end

  class SearchSettings
    include YAML::Serializable

    property query_limit_default : Int32
    property query_limit_maximum : Int32

    property suggest_limit_default : Int32
    property suggest_limit_maximum : Int32

    property list_limit_default : Int32
    property list_limit_maximum : Int32

    property term_index_limit : UInt8 = 10
    property popularity_weight : Float32 = 0.3
    property popularity_index : Int32
  end
end
