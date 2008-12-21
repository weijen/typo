class RedirectController < ContentController
  session :off

  def redirect
    if (params[:from].first == 'articles')
      path = request.path.sub('/articles', '')
      url_root = self.class.relative_url_root
      path = url_root + path unless url_root.nil?
      redirect_to path, :status => 301
      return
    end

    r = Redirect.find_by_from_path(params[:from].join("/"))

    if(r)
      path = r.to_path
      url_root = self.class.relative_url_root
      path = url_root + path unless url_root.nil? or path[0,url_root.length] == url_root
      redirect_to path, :status => 301
    else
      render :text => "Page not found", :status => 404
    end
  end
  
  def redirect_article_with_html
    redirect_to "/#{params[:title]}.html", :status => 301
  end
  
  def redirect_category_with_html
    redirect_to "/category/#{params[:id]}/page/#{params[:page]}.html", :status => 301
  end

  def redirect_tag_with_html
    redirect_to "/tag/#{params[:id]}/page/#{params[:page]}.html"
  end

  def redirect_tags_with_html
    redirect_to "/tags/page/#{params[:page]}.html"
  end

  def redirect_page_with_html
    redirect_to "/pages/#{params[:name]}.html"
  end
  
  def redirect_dates_with_html
    if params[:day]
      redirect_to "/#{params[:year]}/#{params[:month]}/#{params[:day]}/page/#{params[:page]}.html", :status => 301
    elsif params[:month]
      redirect_to "/#{params[:year]}/#{params[:month]}/page/#{params[:page]}.html", :status => 301
    elsif params[:year]
      redirect_to "/#{params[:year]}/page/#{params[:page]}.html", :status => 301
    else
      redirect_to "/page/#{params[:page]}.html", :status => 301
    end
  end
  
end
