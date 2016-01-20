task :default => :convert_notebook

desc "Convert the all notebooks in notebook dir into markdown."
task :convert_notebook do
  dir = './notebooks/'

  Dir.chdir(dir) do
    notebooks = Dir['*.ipynb']
    notebooks.each do |notebook| 
      system "jupyter-nbconvert --config jekyll-post " + notebook 
    end
  end
end
