require 'rexml/document'
require 'ostruct'
require 'rexchange/dav_move_request'
require 'time'

module RExchange
  
  class Folder
    CONTENT_TYPES = {}
  end
  
  class GenericItem
    include REXML
    include Enumerable

    attr_accessor :attributes

    def initialize(session, dav_property_node)
      @attributes = {}
      @session = session

      dav_property_node.elements.each do |element|
        namespaced_name = element.namespace + element.name
        
        if element.name =~ /date$/i
          @attributes[namespaced_name] = Time::parse(element.text)
        else
          @attributes[namespaced_name] = element.text
        end
      end
    end

    # Set the default CONTENT_CLASS to the class name, and define a
    # dynamic query method for the derived class.
    def self.inherited(base)
      base.const_set('CONTENT_CLASS', base.to_s.split('::').last.downcase)
      
      def base.query(path)
        <<-QBODY
          SELECT
            #{self::FIELD_NAMES.map { |f| '"' + f + '"' }.join(',')}
          FROM SCOPE('shallow traversal of "#{path}"')
          WHERE "DAV:ishidden" = false
            AND "DAV:isfolder" = false
            AND "DAV:contentclass" = 'urn:content-classes:#{self::CONTENT_CLASS}'
        QBODY
      end
    end
    
    # This handy method is meant to be called from any inheriting
    # classes. It is used to bind types of folders to particular
    # Entity classes so that the folder knows what type it's
    # enumerating. So for a "calendarfolder" you'd call:
    #   set_folder_type 'calendarfolder' # or just 'calendar'
    def self.set_folder_type(dav_name)
      Folder::CONTENT_TYPES[dav_name.sub(/folder$/, '')] = self
    end
    
    # --Normally Not Used--
    # By default the CONTENT_CLASS is determined by the name
    # of your class. So for the Appointment class the
    # CONTENT_CLASS would be 'appointment'.
    # If for some reason this convention doesn't suit you,
    # you can use this method to set the appropriate value
    # (which is used in queries).
    # For example, the DAV:content-class for contacts is:
    #   'urn:content-classes:person'
    # Person doesn't strike me as the best name for our class though.
    # Most people would refer to an entry in a Contacts folder as
    # a Contact. So that's what we call our class, and we use this method
    # to make sure everything still works as it should.
    def self.set_content_class(dav_name)
      const_set('CONTENT_CLASS', dav_name)
    end
    
    # Defines what attributes are used in queries, and
    # what methods they map to in instances. You should
    # pass a Hash of method_name and namespaced-attribute-name pairs.
    def self.dav_attr_accessor(mappings)
      const_set('FIELD_NAMES', mappings.values)

      mappings.each_pair do |k,v|
        
        define_method(k) do
          @attributes[v]
        end
        
        define_method("#{k.to_s.sub(/\?$/, '')}=") do |value|
          @attributes[v] = value
        end
        
      end
    end
    
    # Retrieve an Array of items (such as Contact, Message, etc)
    def self.find(credentials, path, conditions = nil)
      qbody = <<-QBODY
        <?xml version="1.0"?>
  			<D:searchrequest xmlns:D = "DAV:">
  				 <D:sql>
           #{conditions.nil? ? query(path) : search(path, conditions)}
           </D:sql>
        </D:searchrequest>
      QBODY
      
      response = DavSearchRequest.execute(credentials, :body => qbody)

      items = []
      xpath_query = "//a:propstat[a:status/text() = 'HTTP/1.1 200 OK']/a:prop"

      Document.new(response.body).elements.each(xpath_query) do |m|
        items << self.new(credentials, m)
      end

      items
    end
  end
end