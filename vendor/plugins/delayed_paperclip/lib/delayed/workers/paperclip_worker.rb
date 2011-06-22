class PaperclipWorker < Workling::Base
  def process(options = {})
    instance = options[:class_name].constantize.find(options[:id])

    process_job(instance, options[:attachment]) do
      instance.send(options[:attachment]).reprocess!
      instance.send("#{options[:attachment]}_processed!")
    end
  end
  
  private
  def process_job(instance, attachment_name)
    instance.send(attachment_name).job_is_processing = true
    yield
    instance.send(attachment_name).job_is_processing = false        
  end
end