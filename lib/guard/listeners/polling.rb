module Guard
  class Polling < Listener

    def initialize(*)
      super
      @latency = 1.5
    end

    def start
      @stop = false
      super
      watch_change
    end

    def stop
      super
      @stop = true
    end
    # only looks for content changes, not mtime changes
    # useful when monitoring files across NFS where system time and file mtime are based on different clocks
    def file_modified?(path)
      file_content_modified?(path, sha1_checksum(path))
    end

    def file_content_modified?(path, sha1_checksum)
      if @sha1_checksums_hash.has_key? path
        if @sha1_checksums_hash[path] != sha1_checksum
          set_sha1_checksums_hash(path, sha1_checksum)
          true
        else
          false
        end
      else
        set_sha1_checksums_hash(path, sha1_checksum)
        false
      end
    end

  private

    def watch_change
      until @stop
        start = Time.now.to_f
        files = modified_files([@directory], :all => true)
        @callback.call(files) unless files.empty?
        nap_time = @latency - (Time.now.to_f - start)
        sleep(nap_time) if nap_time > 0
      end
    end

    def watch(directory)
      @existing = all_files
    end

  end
end
