extends Control

class CustomSorter:
	static func sort_by_width(a, b):
		if a.get_width() > b.get_width():
			return true
		return false

onready var save_location_label = $"%SaveLocationLabel"
onready var selected_files = $"%SelectedFiles"
onready var code_block = $"%CodeBlock"

onready var open_file_dialog = $"%OpenFileDialog"
onready var save_file_dialog = $"%SaveFileDialog"
onready var generate = $"%Generate"
var file_paths:PoolStringArray = []
var names=[]
var images=[]
var sorted_images=[]
var dict={}
var final_img:Image
var save_path:String = ''
var max_width=0
var total_height=0
var final_height=0
var lossy_quality=0
var compress=false

var code=''
var css_class_name=""

func _process(_delta):
	if file_paths.size() == 0 or save_path == '' or css_class_name=='':
		generate.disabled = true
	else:
		generate.disabled = false

func loadImages(paths:PoolStringArray):
	for path in paths:
		var img = Image.new()
		img.load(path)
		var w = img.get_width()
		var h = img.get_height()
		if w > max_width:
			max_width = w
		total_height+=h
		images.append(img)
	var _i=0
	for el in images:
		dict[el]=names[_i]
		_i+=1
#	print(images)
	sorted_images=images.duplicate(true)
	sorted_images.sort_custom(CustomSorter,"sort_by_width")
#	print(sorted_images)
#	print(dict)

func _on_PickFiles_pressed():
	open_file_dialog.popup()


func _on_Save_Location_pressed():
	save_file_dialog.popup()


func _on_SaveFileDialog_file_selected(path):
	save_path=path
	save_location_label.text=path


func _on_Exit_pressed():
	get_tree().quit()


func _on_OpenFileDialog_files_selected(paths):
	names.clear()
	images.clear()
	dict.clear()
	sorted_images.clear()
	
	max_width=0
	total_height=0
	final_height=0
	code_block.text=''
	
	file_paths=paths
	for i in paths:
		names.append(i.get_file().get_basename())
	selected_files.text=str(names.size())+" file(s) selected"
	loadImages(paths)


func _on_Generate_pressed():
	#generate css initial part
	code=""
	for nm in names:
		code+="."+css_class_name+nm+", "
	code.erase(code.length() - 2, 1)
	code+="{\n	 max-width: 100%;\n	background-size: 100%;\n	background-image: url();\n}\n\n"
	
	#generate image
#	final_height = total_height + ((images.size() - 1) * offset)
	final_height = (1.5 * total_height) - int(float(sorted_images.back().get_height())/2)
#	print(total_height)
#	print(final_height)
	final_img=Image.new()
	final_img.create(max_width, final_height, false, Image.FORMAT_RGBA8)
	var y_offset = 0
	for i in sorted_images:
		var w = i.get_width()
		var h = i.get_height()

		#individual class generation
		var temp = Image.new()
		temp.create(w,h,false,Image.FORMAT_RGBA8)
		code+="."+css_class_name+dict[i]+" {\n"
		code+="	background-position: 0 "+str((float(y_offset)/(final_height-h))*100)+"%;\n	background-size: "+str((float(max_width)/w)*100)+"%;\n"
		code+="	content: url('data:image/png;base64,"+ str(Marshalls.raw_to_base64(temp.save_png_to_buffer())) +"');"+'\n}\n\n'

		#final img generation
		i.convert(Image.FORMAT_RGBA8)
		final_img.blit_rect(i, Rect2(0,0,w,h), Vector2(0,y_offset))
#		y_offset += h + offset
		y_offset += h + int(float(h)/2)
	if compress:
# warning-ignore:return_value_discarded
		final_img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC, lossy_quality)
# warning-ignore:return_value_discarded
	final_img.save_png(save_path)
	code_block.text=code


func _on_SpinBox_value_changed(value):
	lossy_quality=int(value)


func _on_ClassName_text_changed(new_text):
	css_class_name=new_text


func _on_CopyToClipboard_pressed():
	OS.set_clipboard(code)


func _on_CheckBox_toggled(button_pressed):
	compress=button_pressed
