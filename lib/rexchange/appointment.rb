require 'rexchange/generic_item'

module RExchange
  class Appointment < GenericItem
    
    set_folder_type 'calendar'
  
    attribute_mappings :all_day_event => 'urn:schemas:calendar:alldayevent',
      :busy_status => 'urn:schemas:calendar:busystatus',
      :contact => 'urn:schemas:calendar:contact',
      :contact_url => 'urn:schemas:calendar:contacturl',
      :created_on => 'urn:schemas:calendar:created',
      :description_url => 'urn:schemas:calendar:descriptionurl',
      :end_at => 'urn:schemas:calendar:dtend',
      :created_at => 'urn:schemas:calendar:dtstamp',
      :start_at => 'urn:schemas:calendar:dtstart',
      :duration => 'urn:schemas:calendar:duration',
      :expires_on => 'urn:schemas:calendar:exdate',
      :expiry_rule => 'urn:schemas:calendar:exrule',          
      :has_attachment? => 'urn:schemas:httpmail:hasattachment', 
      :html => 'urn:schemas:httpmail:htmldescription', 
      :modified_on => 'urn:schemas:calendar:lastmodified', 
      :location => 'urn:schemas:calendar:location', 
      :location_url => 'urn:schemas:calendar:locationurl', 
      :meeting_status => 'urn:schemas:calendar:meetingstatus', 
      :normalized_subject => 'urn:schemas:httpmail:normalizedsubject', 
      :priority => 'urn:schemas:httpmail:priority', 
      :recurres_on => 'urn:schemas:calendar:rdate', 
      :reminder_offset => 'urn:schemas:calendar:reminderoffset', 
      :reply_time => 'urn:schemas:calendar:replytime', 
      :sequence => 'urn:schemas:calendar:sequence', 
      :subject => 'urn:schemas:httpmail:subject', 
      :body => 'urn:schemas:httpmail:textdescription', 
      :timezone => 'urn:schemas:calendar:timezone', 
      :uid => 'urn:schemas:calendar:uid',
      :required_attendees => 'urn:schemas:httpmail:to',
    	:organizer => 'urn:schemas:calendar:organizer'

    # Conditions supported:
    #   :start_min => Include appointments that end on or after Time value
    #                 Use end instead of start to include overlapping appointments.
    #   :start_max => Include appointments that start before Time value
    def self.search(path, conditions)
      query = <<-QBODY
         SELECT #{self::ATTRIBUTE_MAPPINGS.values.map { |f| '"' + f + '"' }.join(',')}
         FROM SCOPE('shallow traversal of "#{path}"')
         WHERE "DAV:ishidden" = false
           AND "DAV:isfolder" = false
           AND "DAV:contentclass" = 'urn:content-classes:#{self::CONTENT_CLASS}'
       QBODY

      # Add additional "WHERE" expressions for each condition specified
      conditions.each do |predicate, value|
        unless self.respond_to?(predicate, true)
          raise ArgumentError, "#{predicate} is not a valid condition"
        end
        query += "  AND " + send(predicate, value)
      end

      query
    end

    private

    # Supported Search Predicates

    # Only include appointments that start on or after the specified time.
    def self.start_min(time)
      <<-EXPRESSION
        "urn:schemas:calendar:dtend" &gt;= '#{time.utc.strftime("%Y/%m/%d %H:%M:%S")}'
      EXPRESSION
    end

    # Only include appointments that start before the specified time.
    def self.start_max(time)
      <<-EXPRESSION
        "urn:schemas:calendar:dtstart" &lt; '#{time.utc.strftime("%Y/%m/%d %H:%M:%S")}'
      EXPRESSION
    end

  end
end  