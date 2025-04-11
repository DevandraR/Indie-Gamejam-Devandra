extends Node

func _ready():
    # Make sure we're starting with the right setup
    setup_scene()
    
    # Ensure parallax layers are large enough for any zoom level
    update_parallax_scale()

func setup_scene():
    # If we don't already have a ParallaxBackground, create one
    if not has_node("ParallaxBackground"):
        # Remove existing TextureRect if it exists
        if has_node("TextureRect"):
            var old_texture = $TextureRect
            var texture_path = old_texture.texture.resource_path
            var texture_size = old_texture.size
            remove_child(old_texture)
            old_texture.queue_free()
            
            # Create ParallaxBackground and add sea texture
            var parallax_bg = ParallaxBackground.new()
            var parallax_layer = ParallaxLayer.new()
            var texture_rect = TextureRect.new()
            
            # Set up mirroring for infinite scrolling
            parallax_layer.motion_mirroring = Vector2(1920, 1080)
            
            # Set up texture
            texture_rect.texture = load(texture_path)
            texture_rect.size = Vector2(1920, 1080)
            texture_rect.stretch_mode = TextureRect.STRETCH_TILE
            
            # Build the node structure
            add_child(parallax_bg)
            parallax_bg.add_child(parallax_layer)
            parallax_layer.add_child(texture_rect)
    else:
        # Update existing ParallaxBackground
        update_parallax_scale()

func update_parallax_scale():
    # Get the viewport size and use a larger mirroring size to ensure coverage
    var viewport_size = get_viewport().get_visible_rect().size
    var parallax_layer = $ParallaxBackground/ParallaxLayer
    
    # Make mirroring size much larger than the viewport to handle zoom
    var mirroring_size = Vector2(
        max(viewport_size.x * 3, 3840),  # At least 2x 1920 or 3x viewport width
        max(viewport_size.y * 3, 2160)   # At least 2x 1080 or 3x viewport height
    )
    
    # Update mirroring size for infinite scrolling in all directions
    parallax_layer.motion_mirroring = mirroring_size
    
    # Ensure the texture rect is large enough and uses the right stretch mode
    var texture_rect = $ParallaxBackground/ParallaxLayer/TextureRect
    texture_rect.size = mirroring_size
    texture_rect.stretch_mode = TextureRect.STRETCH_TILE
    
    # Add scale factor to the ParallaxLayer for better coverage
    $ParallaxBackground.scroll_ignore_camera_zoom = false