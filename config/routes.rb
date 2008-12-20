module ActionController
  module Resources
    class InflectedResource < Resource
      def member_path
        @member_path ||= "#{singular_path}/:id"
      end

      def nesting_path_prefix
        @nesting_path_prefix ||= "#{singular_path}/:#{singular}_id"
      end

      protected
      def singular_path
        @singular_path ||= "#{path_prefix}/#{singular}"
      end
    end

    def inflected_resource(*entities, &block)
      options = entities.last.is_a?(Hash) ? entities.pop : { }
      entities.each { |entity| map_inflected_resource entity, options.dup, &block }
    end

    private
    def map_inflected_resource(entities, options = { }, &block)
      resource = InflectedResource.new(entities, options)

      with_options :controller => resource.controller do |map|
        map_collection_actions(map, resource)
        map_default_collection_actions(map, resource)
        map_new_actions(map, resource)
        map_member_actions(map, resource)

        if block_given?
          with_options(:path_prefix => resource.nesting_path_prefix, &block)
        end
      end
    end
  end
end

ActionController::Routing::Routes.draw do |map|

  # default
  map.index '', :controller  => 'articles', :action => 'index'
  map.admin 'admin', :controller  => 'admin/dashboard', :action => 'index'

  # make rss feed urls pretty and let them end in .xml
  # this improves caches_page because now apache and webrick will send out the
  # cached feeds with the correct xml mime type.

  map.xml 'articles.rss', 
  :controller => 'articles', :action => 'index', :format => 'rss'
  map.xml 'articles.atom', 
  :controller => 'articles', :action => 'index', :format => 'atom'
  map.xml 'xml/itunes/feed.xml', :controller => 'xml', :action => 'itunes'
  map.xml 'xml/articlerss/:id/feed.xml', :controller => 'xml', :action => 'articlerss'
  map.xml 'xml/commentrss/feed.xml', :controller => 'xml', :action => 'commentrss'
  map.xml 'xml/trackbackrss/feed.xml', :controller => 'xml', :action => 'trackbackrss'

  map.xml 'xml/:format/feed.xml', :controller => 'xml', :action => 'feed', :type => 'feed'
  map.xml 'xml/:format/:type/feed.xml', :controller => 'xml', :action => 'feed'
  map.xml 'xml/:format/:type/:id/feed.xml', :controller => 'xml', :action => 'feed'
  map.xml 'xml/rss', :controller => 'xml', :action => 'feed', :type => 'feed', :format => 'rss'
  map.xml 'sitemap.xml', :controller => 'xml', :action => 'feed', :format => 'googlesitemap', :type => 'sitemap'

  map.resources :comments, :name_prefix => 'admin_'
  map.resources :trackbacks
  map.resources :users

  map.datestamped_resources(:articles,
                            :collection => {
                              :search => :get, :comment_preview => :any,
                              :archives => :get
                            },
                            :member => {
                              :markup_help => :get
                            }) do |dated|
    dated.resources :trackbacks
    dated.connect 'trackbacks', :controller => 'trackbacks', :action => 'create', :conditions => {:method => :post}
  end
  
  map.connect "trackbacks/:id/:day/:month/:year",
    :controller => 'trackbacks', :action => 'create', :conditions => {:method => :post}

  # Redirects from old permalinks
  map.connect "articles/:controler/:name",
    :controller => 'redirect', :action => 'redirect'
    map.connect "articles/:controler",
      :controller => 'redirect', :action => 'redirect'

  map.inflected_resource(:categories, :path_prefix => '')
  map.connect '/category/:id/page/:page.html',
    :controller => 'categories', :action => 'show'
  map.connect '/category/:id/page/:page',
    :controller => 'redirect', :action => 'redirect_category_with_html'

  map.inflected_resource(:authors, :path_prefix => '')
  
  map.inflected_resource(:tags, :path_prefix => '')
  map.connect '/tag/:id/page/:page.html',
    :controller => 'tags', :action => 'show'
  map.connect '/tags/page/:page.html', 
    :controller => 'tags', :action => 'index'
    map.connect '/tag/:id/page/:page',
      :controller => 'redirect', :action => 'redirect_tag_with_html'
    map.connect '/tags/page/:page', 
      :controller => 'redirect', :action => 'redirect_tags_with_html'
  
  map.resources(:feedback)

  # allow neat perma urls
  map.connect ':title.html',
    :controller => 'articles', :action => 'show'
  map.connect ':title',
    :controller => 'redirect', :action => 'redirect_article_with_html'

  map.connect ':title' + '.rss',
      :controller => 'articles', :action => 'show', :format => 'rss'

  map.connect ':title' + '.atom',
      :controller => 'articles', :action => 'show', :format => 'atom'
  
  map.connect ':title/comments',
    :controller => 'comments', :action => 'create', :conditions => {:method => :post}
  
  map.connect 'page/:page.html',
    :controller => 'articles', :action => 'index',
    :page => /\d+/

  map.connect 'page/:page',
    :controller => 'redirect', :action => 'redirect_dates_with_html'

  date_options = { :year => /\d{4}/, :month => /(?:0?[1-9]|1[012])/, :day => /(?:0[1-9]|[12]\d|3[01])/ }

  map.with_options(:conditions => {:method => :get}) do |get|
    get.with_options(date_options.merge(:controller => 'articles')) do |dated|
      dated.with_options(:action => 'index') do |finder|
        # new URL
        finder.connect ':year/page/:page.html',
          :month => nil, :day => nil, :page => /\d+/
        finder.connect ':year/:month/page/:page.html',
          :day => nil, :page => /\d+/
        finder.connect ':year/:month/:day/page/:page.html', :page => /\d+/
        
        finder.connect ':year',
          :month => nil, :day => nil
        finder.connect ':year/:month',
          :day => nil
        finder.connect ':year/:month/:day', :page => nil
      end
    end

    map.connect ':year/page/:page',
      :controller => 'redirect', :action => 'redirect_dates_with_html'
    map.connect ':year/:month/page/:page',
      :controller => 'redirect', :action => 'redirect_dates_with_html'
    map.connect ':year/:month/:day/page/:page', 
      :controller => 'redirect', :action => 'redirect_dates_with_html'

    get.connect 'pages/*name.html',:controller => 'articles', :action => 'view_page'
    get.connect 'pages/*name',:controller => 'redirect', :action => 'redirect_page_with_html'

    get.with_options(:controller => 'theme', :filename => /.*/, :conditions => {:method => :get}) do |theme|
      theme.connect 'stylesheets/theme/:filename', :action => 'stylesheets'
      theme.connect 'javascripts/theme/:filename', :action => 'javascript'
      theme.connect 'images/theme/:filename',      :action => 'images'
    end

    # For the tests
    get.connect 'theme/static_view_test', :controller => 'theme', :action => 'static_view_test'

    map.connect 'plugins/filters/:filter/:public_action',
      :controller => 'textfilter', :action => 'public_action'
  end

  # Work around the Bad URI bug
  %w{ accounts articles backend files live sidebar textfilter xml }.each do |i|
    map.connect "#{i}", :controller => "#{i}", :action => 'index'
    map.connect "#{i}/:action", :controller => "#{i}"
    map.connect "#{i}/:action/:id", :controller => i, :id => nil
  end

  %w{advanced blacklist cache categories comments content feedback general pages
     resources sidebar textfilters themes trackbacks users settings tags }.each do |i|
    map.connect "/admin/#{i}", :controller => "admin/#{i}", :action => 'index'
    map.connect "/admin/#{i}/:action/:id", :controller => "admin/#{i}", :action => nil, :id => nil
  end

  map.connect '*from', :controller => 'redirect', :action => 'redirect'

  map.connect(':controller/:action/:id') do |default_route|
    class << default_route
      def recognize_with_deprecation(path, environment = {})
        RAILS_DEFAULT_LOGGER.info "#{path} hit the default_route buffer"
        recognize_without_deprecation(path, environment)
      end
      alias_method_chain :recognize, :deprecation

      def generate_with_deprecation(options, hash, expire_on = {})
        RAILS_DEFAULT_LOGGER.info "generate(#{options.inspect}, #{hash.inspect}, #{expire_on.inspect}) reached the default route"
        #         if RAILS_ENV == 'test'
        #           raise "Don't rely on default route generation"
        #         end
        generate_without_deprecation(options, hash, expire_on)
      end
      alias_method_chain :generate, :deprecation
    end
  end
end
