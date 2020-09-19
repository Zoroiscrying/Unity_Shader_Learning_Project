using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class TransparentShaderGUI : ShaderGUI
{
    Material target;
    private MaterialEditor editor;
    private MaterialProperty[] properties;
    bool shouldShowAlphaCutoff;
    
    enum RenderingMode {
        Cutout, Fade
    }
    
    struct RenderingSettings {
        public RenderQueue queue;
        public string renderType;
        public BlendMode srcBlend, dstBlend;
        public bool zWrite;
        
        public static RenderingSettings[] modes = {
            new RenderingSettings() {
                queue = RenderQueue.Geometry,
                renderType = "",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings() {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.SrcAlpha,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            }
        };
    }
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        editor = materialEditor;
        this.target = materialEditor.target as Material;
        this.properties = properties;
        DoRenderingMode();
        DoMain();
        if (shouldShowAlphaCutoff) {
            DoAlphaCutoff();
        }
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(
            MakeLabel(mainTex, "Albedo (RGB)"), 
            mainTex, 
            FindProperty("_Tint"));
        
    }

    void DoRenderingMode()
    {
        RenderingMode mode = RenderingMode.Cutout;
        
        shouldShowAlphaCutoff = false;
        if (IsKeywordEnabled("_RENDERING_CUTOUT")) {
            mode = RenderingMode.Cutout;
            shouldShowAlphaCutoff = true;
        }		
        else if (IsKeywordEnabled("_RENDERING_FADE")) {
            mode = RenderingMode.Fade;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(
            MakeLabel("Rendering Mode"), mode
        );

        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
            SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
            RenderingSettings settings = RenderingSettings.modes[(int)mode+1];
            foreach (Material m in editor.targets) {
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
                m.SetInt("_SrcBlend", (int)settings.srcBlend);
                m.SetInt("_DstBlend", (int)settings.dstBlend);
                m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
            }
        }
        
//        if (mode == RenderingMode.Fade || mode == RenderingMode.Transparent) {
//            DoSemitransparentShadows();
//        }

        if (mode == RenderingMode.Fade) {
            DoSemitransparentShadows();
        }
            
    }

    void DoSemitransparentShadows()
    {
        EditorGUI.BeginChangeCheck();
        bool semitransparentShadows =
            EditorGUILayout.Toggle(
                MakeLabel("Semitransp. Shadows", "Semitransparent Shadows"),
                IsKeywordEnabled("_SEMITRANSPARENT_SHADOWS")
            );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_SEMITRANSPARENT_SHADOWS", semitransparentShadows);
        }
        if (!semitransparentShadows) {
            shouldShowAlphaCutoff = true;
        }
    }
    
    void DoAlphaCutoff () {
        MaterialProperty slider = FindProperty("_AlphaCutoff");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }
    
    void SetKeyword (string keyword, bool state) {
        if (state) {
            foreach (Material m in editor.targets) {
                m.EnableKeyword(keyword);
            }
        }
        else {
            foreach (Material m in editor.targets) {
                m.DisableKeyword(keyword);
            }
        }
    }
    
    void RecordAction (string label) {
        editor.RegisterPropertyChangeUndo(label);
    }
    
    bool IsKeywordEnabled (string keyword) {
        return target.IsKeywordEnabled(keyword);
    }
    
    MaterialProperty FindProperty (string name) {
        return FindProperty(name, properties);
    }
    
    static GUIContent staticLabel = new GUIContent();
	
    static GUIContent MakeLabel (string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
    
    static GUIContent MakeLabel (
        MaterialProperty property, string tooltip = null
    ) {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}
