SITE = <<'END'
<?xml version="1.0" encoding="utf-8"?>
<?xml-stylesheet type="text/css" href="style.css"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="pl">    
<head>
  <title>Formula!</title>
  <script type="text/javascript">
  var eqOld = "";
  function update() 
{
     var eq = document.getElementById('formula').value;
     eq = encodeURIComponent(eq);
     if(eq != eqOld) { document.images[0].src = '/img/' + eq; }
     eqOld = eq;
}
</script>
</head>
<body>
Enter your secret forumla:</br>
  <form action="/" method="post">
    <textarea onkeyup="update()" "rows="10" cols="50" id="formula" name="formula">FORMULA</textarea><br/>
    <input type="submit" value="Create" />
  <p><img src="IMG_URL" /></p>
</body>
</html>
END

Merb::Config.use { |c|
  c[:framework]           = { :public => [Merb.root / "public", nil] }
  c[:session_store]       = 'none'
  c[:exception_details]   = true
	c[:log_level]           = :debug # or error, warn, info or fatal
  c[:log_stream]          = STDOUT
	c[:reload_classes]      = false
	c[:reload_templates]    = false
}
Merb::Router.prepare do
  match('/').to(:controller => 'seksi', :action =>'index')
  match(%r{/img/(.*)}).to(:controller => 'seksi', :action => 'image', :for => '[1]')
end

Merb.add_mime_type(:png, :to_png, %w[image/png], "Content-Type" => "image/png")

class Seksi < Merb::Controller    
  PRE ="\\documentclass[12pt]{article}\n\\usepackage{color}\n\\usepackage[dvips]{graphicx}\n\\pagestyle{empty}\n\\pagecolor{white}\n\\begin{document}\n{\\color{black}\n\\begin{eqnarray*}\n"
  POST = "\n\\end{eqnarray*}}\n\\end{document}"
  TEMP = '/tmp/tex2img/'
  
  def index
    if request.post?
    end
    render SITE.sub('FORMULA', params[:formula]||'').sub('IMG_URL', "/img/#{(params[:formula]||'').gsub('"', "''")}")
  end
  
  def image
    return unless params[:for]
    pwd = FileUtils.pwd
    filename = Time.now.to_f.to_s + rand.to_s
      
    FileUtils.mkdir_p TEMP
    FileUtils.cd TEMP
    File.open(filename+'.tex',"w"){|file| file.puts PRE + params[:for].gsub(/%([a-fA-F\d]{2})/){eval("0x#$1").chr} + POST}

    `latex -interaction=batchmode #{filename}.tex -output-format=dvi`
    `dvips -o #{filename}.eps -E #{filename}.dvi 2> /dev/null`
    `convert +adjoin -antialias -density 150x150 #{filename}.eps #{filename}.png`

    content =  File.read(filename+".png")

    FileUtils.rm %w(png eps dvi aux log tex).map{|x| filename+'.'+x}
    FileUtils.cd pwd

    render content, :format => :png, :layout => false
  end
end
