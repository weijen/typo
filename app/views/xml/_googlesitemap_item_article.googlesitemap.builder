xm.url do
  xm.loc "#{this_blog.base_url}/#{item.permalink}.html"
  xm.lastmod item.updated_at.xmlschema
  xm.priority 0.8
end
