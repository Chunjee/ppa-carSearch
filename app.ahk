#NoEnv
SetBatchLines, -1
#SingleInstance force

#Include html_gui.ahk

#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk
#Include json.ahk\export.ahk
#Include wrappers.ahk\export.ahk
#Include winhttprequest.ahk\export.ahk
#Include neutron.ahk\export.ahk


A := new biga()
; global http := new WinHttpRequest()
; Endpoint := "https://www.cargurus.com/Cars/getCarPickerReferenceDataAJAX.action?showInactive=false&useInventoryService=true&localCountryCarsOnly=true&outputFormat=REACT&quotableCarsOnly=false"
HTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1") ;Create COM Object

; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("gui\index.html")
; Use the Gui method to set a custom label prefix for GUI events.
neutron.Gui("+LabelNeutron")
neutron.Show()


; read and parse needed stuff from cars object
FileRead, Carsjson, cars.txt
global carsObj := JSON.parse(Carsjson).allMakerModels.makers
allManufacturers := A.map(carsObj, A.property("name"))
;  => ["Lexus", "Acura", "Polestar", "Opel", "Hillman", "MINI", "Muntz", "Nissan", "smart", "Subaru", "Bentley", "Austin", "Panoz", "BMW", "Hyundai", "Triumph", "Peugeot", "Genesis", "Lincoln", "Tesla", "AM General", "Mitsubishi", "Messerschmitt", "Hudson", "Buick", "Plymouth", "Suzuki", "Ariel", "SRT", "Pininfarina", "Bricklin", "Lotus", "Honda", "Bugatti", "De Tomaso", "Pontiac", "Pagani", "Moskvitch", "Volkswagen", "Cadillac", "Datsun", "Isuzu", "Maserati", "Austin-Healey", "Studebaker", "Toyota", "Daewoo", "Porsche", "VPG", "Volvo", "Chrysler", "DeLorean", "Jaguar", "Maybach", "Sunbeam", "Excalibur", "Rolls-Royce", "Eagle", "Dodge", "Graham", "Willys", "Jeep", "Rover", "FIAT", "Kaiser", "Mobility Ventures", "Mazda", "AMC", "Lancia", "Nash", "Geo", "Saab", "McLaren", "Edsel", "Ferrari", "Cord", "Kia", "Freightliner", "Alfa Romeo", "Karma", "Jensen", "Mercedes-Benz", "DeSoto", "Saturn", "Franklin", "GMC", "Citroen", "INFINITI", "Fisker", "Morgan", "Chevrolet", "Lamborghini", "RAM", "International Harvester", "Riley", "Autobianchi", "Shelby", "MG", "Packard", "Audi", "Mercury", "Aston Martin", "Hummer", "Oldsmobile", "Scion", "Morris", "Land Rover", "Ford"]

; fords := A.filter(obj.allMakerModels.makers, ["name", "Ford"])[1].models
; fordModels := A.map(fords, A.property("name"))
; => ["Bronco", "Bronco Sport", "C-Max Energi", "C-Max Hybrid", "Crown Victoria", "E-Series", ...]

; popularFords := A.map(A.filter(fords, {"popular": true}), "name")
; => ["Bronco", "Bronco Sport", "C-Max Energi", "C-Max Hybrid", "Crown Victoria", "E-Series", ...]
; unpopularFords := A.difference(fordModels, popularFords)
; => ["Aerostar", "Anglia", "Aspire", "Bronco II", "Capri", "Classic Pickup", "Contour", "Country Squire", ...]

return


; find button
fn_submit(neutron, event)
{
	global carsObj, HTTP
	; form will redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that
	; is easily accessed. Fields that have a 'name' attribute will be keyed by
	; that, or if they don't they'll be keyed by their 'id' attribute.
	formData := neutron.GetFormData(event.target)

	; You can access all of the form fields by iterating over the FormData
	; for name, value in formData

	; You can also get field values by name directly. Use object dot notation
	; with the field name/id.
	; out .= "Email: " formData.inputEmail "`n"

	; Find the MAKE ID for the user's input
	; msgbox, % A.print(carsObj)
	brandCode := A.find(carsObj, {"name": formData.inputMake}).id
	; neutron.doc.getElementById("ahk_output").innerText := Convert(out)


	; create http request
	req := {}
	req.inventorySearchWidgetType := "AUTO"
	req.bodyTypeGroupIds := 0 ;coupe
	; req.searchId := "20f6ffe9-3e16-403e-a752-89794f0c5d43"
	req.deliveryFilterType := "SOME"
	req.nonShippableBaseline := "35"
	req.sortDir := "ASC"
	req.sourceContext := "untrackedExternal_false_0"
	req.distance := "500"
	req.sortType := "MILEAGE"
	req.zip := formData.inputZip
	req.startYear := formData.inputStartYear
	req.endYear := formData.inputEndYear
	req["entitySelectingHelper.selectedEntity"] := brandCode
	req["entitySelectingHelper.selectedEntity2"] := formData.inputModel

	endpoint := "https://www.cargurus.com/Cars/preflightResults.action?"
	body := A.join(A.mapValues(req, Func("fn_mapValuesFunc")), "&")

	; send request
	HTTP.Open("GET", endpoint body) ;GET & POST are most frequent, Make sure you UPPERCASE
	HTTP.Send() ;If POST request put data in "Payload" variable
	Response_Text := HTTP.ResponseText
	res := JSON.parse(Response_Text)

	; parse request
	; put all cars in one big array
	vehicles := A.uniq(A.concat(res.listings, res.featuredListings, res.conquestListings, res.priorityListings, res.highlightListings))
	; msgbox, % A.print(vehicles[1].modelName)
	; vehicles := A.filter(vehicles, {"modelName": formData.inputModel})
	vehicles := A.compact(vehicles)
	; modelsFound := A.join(A.map(vehicles, A.property("modelName")))
	; msgbox, % modelsFound
	; Array_Gui(vehicles)
	; pick just the data we like
	; pickedVehicles := A.map(vehicles, Func("fn_pickFields"))

	html := gui_generateTable(vehicles, ["id", "modelName", "trimName", "priceString", "expectedPriceString", "sellerPostalCode", "sellerCity", "serviceProviderName", "localizedTransmission", "accidentCount", "mileageString", "phoneNumberString", "mainPictureUrl"])
	; msgbox, % html
	neutron.qs("#ahk_output").innerHTML := html
}



fn_pickFields(o)
{
	return biga.pick(o, ["modelName", "trimName", "mileageString", "daysOnMarket", "phoneNumberString", "sellerCity", "mainPictureUrl"])
}

fn_mapValuesFunc(value, key)
{
    return key "=" value
}


; FileInstall all your dependencies, but put the FileInstall lines somewhere
; they won't ever be reached. Right below your AutoExecute section is a great
; location!
FileInstall, gui\Bootstrap.html, gui\Bootstrap.html
FileInstall, gui\bootstrap.min.css, gui\bootstrap.min.css
FileInstall, gui\bootstrap.min.js, gui\bootstrap.min.js
FileInstall, gui\jquery.min.js, gui\jquery.min.js

; The built in GuiClose, GuiEscape, and GuiDropFiles event handlers will work
; with Neutron GUIs. Using them is the current best practice for handling these
; types of events. Here, we're using the name NeutronClose because the GUI was
; given a custom label prefix up in the auto-execute section.
NeutronClose:
ExitApp
return



; ------------------
; functions
; ------------------

; #Persistent
; Print(obj, quote:=False, end:="`n")
; {
; 	static _ := DllCall("AllocConsole"), cout := FileOpen("CONOUT$", "w")
; 	, escapes := [["``", "``" "``"], ["""", """"""], ["`b", "``b"]
; 	, ["`f", "``f"], ["`r", "``r"], ["`n", "``n"], ["`t", "``t"]]
; 	if IsObject(obj) {
; 		for k in obj
; 			is_array := k == A_Index
; 		until !is_array
; 		cout.Write(is_array ? "[" : "{")
; 		for k, v in obj {
; 			cout.Write(A_Index > 1 ? ", " : "")
; 			is_array ? _ : Print(k, 1, "") cout.Write(": ")
; 			Print(v, 1, "")
; 		} return cout.Write(( is_array ? "]" : "}") end), end ? cout.__Handle : _
; 	} if (!quote || ObjGetCapacity([obj], 1) == "")
; 		return cout.Write(obj . end), end ? cout.__Handle : _
; 	for k, v in escapes
; 		obj := StrReplace(obj, v[1], v[2])
; 	while RegExMatch(obj, "O)[^\x20-\x7e]", m)
; 		obj := StrReplace(obj, m[0], Format(""" Chr({:04d}) """, Ord(m[0])))
; 	return cout.Write("""" obj """" . end), end ? cout.__Handle : _
; }


Array_Gui(Array, Parent="") {
	if !Parent
	{
		Gui, +HwndDefault
		Gui, New, +HwndGuiArray +LabelGuiArray +Resize
		Gui, Margin, 5, 5
		Gui, Add, TreeView, w300 h200

		Item := TV_Add("Array", 0, "+Expand")
		Array_Gui(Array, Item)

		Gui, Show,, GuiArray
		Gui, %Default%:Default

		WinWait, ahk_id%GuiArray%
		WinWaitClose, ahk_id%GuiArray%
		return
	}

	For Key, Value in Array
	{
		Item := TV_Add(Key, Parent)
		if (IsObject(Value))
			Array_Gui(Value, Item)
		else
			TV_Add(Value, Item)
	}
	return

	GuiArrayClose:
	Gui, Destroy
	return

	GuiArraySize:
	GuiControl, Move, SysTreeView321, % "w" A_GuiWidth - 10 " h" A_GuiHeight - 10
	return
}