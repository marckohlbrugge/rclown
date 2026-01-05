class SystemHealth
  def cpu_usage
    if macos?
      output = `top -l 1 -n 0 | grep "CPU usage" 2>/dev/null`.strip
      match = output.match(/(\d+\.\d+)% user/)
      match ? match[1].to_f : nil
    else
      output = `cat /proc/loadavg 2>/dev/null`.strip
      output.split.first&.to_f
    end
  rescue
    nil
  end

  def memory_usage
    if macos?
      output = `vm_stat 2>/dev/null`
      return nil if output.blank?

      page_size = 16384 # Default page size on modern macOS
      pages_free = output.match(/Pages free:\s+(\d+)/)&.[](1)&.to_i || 0
      pages_active = output.match(/Pages active:\s+(\d+)/)&.[](1)&.to_i || 0
      pages_inactive = output.match(/Pages inactive:\s+(\d+)/)&.[](1)&.to_i || 0
      pages_wired = output.match(/Pages wired down:\s+(\d+)/)&.[](1)&.to_i || 0

      total = (pages_free + pages_active + pages_inactive + pages_wired) * page_size
      used = (pages_active + pages_wired) * page_size

      {
        used: format_bytes(used),
        total: format_bytes(total),
        percentage: ((used.to_f / total) * 100).round(1)
      }
    else
      output = `free -b 2>/dev/null`.strip
      return nil if output.blank?

      lines = output.lines
      mem_line = lines.find { |l| l.start_with?("Mem:") }
      return nil unless mem_line

      parts = mem_line.split
      total = parts[1].to_i
      used = parts[2].to_i

      {
        used: format_bytes(used),
        total: format_bytes(total),
        percentage: ((used.to_f / total) * 100).round(1)
      }
    end
  rescue
    nil
  end

  def disk_usage
    output = `df -h / 2>/dev/null`.strip
    return nil if output.blank?

    lines = output.lines
    return nil if lines.length < 2

    parts = lines[1].split
    {
      used: parts[2],
      total: parts[1],
      percentage: parts[4].to_i
    }
  rescue
    nil
  end

  def uptime
    if macos?
      output = `sysctl -n kern.boottime 2>/dev/null`
      match = output.match(/sec = (\d+)/)
      return nil unless match

      boot_time = Time.at(match[1].to_i)
      format_uptime(Time.current - boot_time)
    else
      output = `cat /proc/uptime 2>/dev/null`.strip
      return nil if output.blank?

      seconds = output.split.first.to_f
      format_uptime(seconds)
    end
  rescue
    nil
  end

  def rclone_version
    output = `rclone version 2>/dev/null`.strip
    output.lines.first&.strip
  rescue
    nil
  end

  private
    def macos?
      RUBY_PLATFORM.include?("darwin")
    end

    def format_bytes(bytes)
      if bytes >= 1024**3
        "#{(bytes.to_f / 1024**3).round(1)} GB"
      elsif bytes >= 1024**2
        "#{(bytes.to_f / 1024**2).round(1)} MB"
      else
        "#{(bytes.to_f / 1024).round(1)} KB"
      end
    end

    def format_uptime(seconds)
      days = (seconds / 86400).floor
      hours = ((seconds % 86400) / 3600).floor
      minutes = ((seconds % 3600) / 60).floor

      parts = []
      parts << "#{days}d" if days > 0
      parts << "#{hours}h" if hours > 0 || days > 0
      parts << "#{minutes}m"
      parts.join(" ")
    end
end
