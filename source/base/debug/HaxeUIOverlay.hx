package base.debug;

import base.ScriptHandler.ForeverModule;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.containers.menus.*;
import haxe.ui.styles.Style;
import sys.FileSystem;
import sys.io.File;

class HaxeUIOverlay extends FlxTypedGroup<FlxBasic>
{
	var uiScript:ForeverModule;

	public function new(scriptName:String, scriptPath:String, ?exposure:StringMap<Dynamic>)
	{
		super();
		var xmlPath:String = AssetManager.getPath(scriptName, scriptPath, SPARROW);
		var hxsPath:String = AssetManager.getPath(scriptName, scriptPath, MODULE);
		if (FileSystem.exists(hxsPath))
		{
			var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
			exposure = exposeAll(exposure);
			exposure.set("add", add);
			exposure.set("this", this);
			uiScript = ScriptHandler.loadModule(scriptName, scriptPath, exposure);
			if (uiScript.exists("onCreate"))
				uiScript.get("onCreate")();
		}
		else if (FileSystem.exists(xmlPath))
		{
			var uiComponent = RuntimeComponentBuilder.fromString(File.getContent(xmlPath));
			add(uiComponent);
		}
		//
	}

	override public function update(elapsed:Float)
	{
		if (uiScript != null)
		{
			if (uiScript.exists("onUpdate"))
				uiScript.get("onUpdate")(elapsed);
		}
		super.update(elapsed);
	}

	static function exposeAll(exposeTo:StringMap<Dynamic>)
	{
		// components
		exposeTo.set("Animation", Animation);
		exposeTo.set("Button", Button);
		exposeTo.set("Calendar", Calendar);
		exposeTo.set("Canvas", Canvas);
		exposeTo.set("CheckBox", CheckBox);
		exposeTo.set("ColorPicker", ColorPicker);
		exposeTo.set("Column", Column);
		exposeTo.set("DropDown", DropDown);
		exposeTo.set("HGrid", HGrid);
		exposeTo.set("HorizontalProgress", HorizontalProgress);
		exposeTo.set("HorizontalRange", HorizontalRange);
		exposeTo.set("HorizontalRule", HorizontalRule);
		exposeTo.set("HorizontalScroll", HorizontalScroll);
		exposeTo.set("HorizontalSlider", HorizontalSlider);
		exposeTo.set("Image", Image);
		exposeTo.set("Label", Label);
		exposeTo.set("Link", Link);
		exposeTo.set("NumberStepper", NumberStepper);
		exposeTo.set("OptionBox", OptionBox);
		exposeTo.set("OptionStepper", OptionStepper);
		exposeTo.set("Progress", Progress);
		exposeTo.set("Range", Range);
		exposeTo.set("Rule", Rule);
		exposeTo.set("Scroll", Scroll);
		exposeTo.set("SectionHeader", SectionHeader);
		exposeTo.set("Slider", Slider);
		exposeTo.set("Spacer", Spacer);
		exposeTo.set("Stepper", Stepper);
		exposeTo.set("Switch", Switch);
		exposeTo.set("TabBar", TabBar);
		exposeTo.set("TextArea", TextArea);
		exposeTo.set("TextField", TextField);
		exposeTo.set("Toggle", Toggle);
		exposeTo.set("VerticalProgress", VerticalProgress);
		exposeTo.set("VerticalRange", VerticalRange);
		exposeTo.set("VerticalRule", VerticalRule);
		exposeTo.set("VerticalScroll", VerticalScroll);
		exposeTo.set("VerticalSlider", VerticalSlider);
		exposeTo.set("VGrid", VGrid);
		//
		exposeTo.set("Absolute", Absolute);
		exposeTo.set("Accordion", Accordion);
		exposeTo.set("Box", Box);
		exposeTo.set("ButtonBar", ButtonBar);
		exposeTo.set("CalendarView", CalendarView);
		exposeTo.set("Card", Card);
		exposeTo.set("ContinuousHBox", ContinuousHBox);
		exposeTo.set("Frame", Frame);
		exposeTo.set("Grid", Grid);
		exposeTo.set("Group", Group);
		exposeTo.set("HBox", HBox);
		exposeTo.set("Header", Header);
		exposeTo.set("HorizontalButtonBar", HorizontalButtonBar);
		exposeTo.set("HorizontalSplitter", HorizontalSplitter);
		exposeTo.set("IVirtualContainer", IVirtualContainer);
		exposeTo.set("ListView", ListView);
		exposeTo.set("ScrollView", ScrollView);
		exposeTo.set("SideBar", SideBar);
		exposeTo.set("Splitter", Splitter);
		exposeTo.set("Stack", Stack);
		exposeTo.set("TableView", TableView);
		exposeTo.set("TabView", TabView);
		exposeTo.set("TreeView", TreeView);
		exposeTo.set("TreeViewNode", TreeViewNode);
		exposeTo.set("VBox", VBox);
		exposeTo.set("VerticalButtonBar", VerticalButtonBar);
		exposeTo.set("VerticalSplitter", VerticalSplitter);
		//
		exposeTo.set("Menu", Menu);
		exposeTo.set("MenuBar", MenuBar);
		exposeTo.set("MenuCheckBox", MenuCheckBox);
		exposeTo.set("MenuItem", MenuItem);
		exposeTo.set("MenuOptionBox", MenuOptionBox);
		exposeTo.set("MenuSeparator", MenuSeparator);
		exposeTo.set("Style", Style);

		return exposeTo;
	}
}
