require 'date'
require 'timezone_parser'
require_relative 'time_with_zone'

module Icalendar
  module Values

    class DateTime < Value
      include TimeWithZone

      FORMAT = '%Y%m%dT%H%M%S'

      def initialize(value, params = {})
        if value.is_a? String
          if value.end_with? 'Z'
            params['tzid'] = 'UTC'
          elsif params['tzid']
            # Ensure we have a valid Ruby Timezone
            params['tzid'] = validate_tzid(params['tzid'])
          end

          begin
            parsed_date = ::DateTime.strptime(value, FORMAT)
          rescue ArgumentError => e
            raise FormatError.new("Failed to parse \"#{value}\" - #{e.message}")
          end

          super parsed_date, params
        elsif value.respond_to? :to_datetime
          super value.to_datetime, params
        else
          super
        end
      end

      def value_ical
        if tz_utc
          "#{strftime FORMAT}Z"
        else
          strftime FORMAT
        end
      end

      def <=>(other)
        if other.is_a?(Icalendar::Values::Date) || other.is_a?(Icalendar::Values::DateTime)
          value_ical <=> other.value_ical
        else
          nil
        end
      end

      def utc?
        value.respond_to?(:utc?) ? value.utc? : value.to_time.utc?
      end

      def validate_tzid(tzids)
        Array(tzids).each do |tzid|
          zone_name = TimezoneParser.getTimezones(tzid).first

          if zone_name
            return zone_name
          else
            if /(?<tz>\w+\/\w+\Z)/.match(tzid)
              begin
                tz_match = Regexp.last_match[:tz]
                TZInfo::Timezone.get(tz_match)
                return tz_match
              rescue TZInfo::InvalidTimezoneIdentifier
                next
              end
            end
          end
        end

        # If we did not found a valid timezone return what we got
        tzids
      end

      class FormatError < ArgumentError
      end

    end

  end
end
