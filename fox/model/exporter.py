import bpy
import bmesh
import struct

bl_info = {
    "name": "Game Asset Exporter",
    "author": "Isaac McCracken",
    "version": (2022, 7, 18),
    "blender": (3, 2, 1),
    "location": "Properties > Object > Export",
    "description": "One-click export game asset files.",
    "category": "Export"}





# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper, axis_conversion
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator

def axis_matrix():
    return axis_conversion("-Y", "Z", bpy.context.scene.exportProperties.forwardAxis, bpy.context.scene.exportProperties.upAxis).to_4x4()

def write_some_data(context, filepath, use_some_setting, s):
    print("running write_some_data...")
    f = open(filepath, 'w', encoding='utf-8')
    f.write("Hello World %s" % use_some_setting)
    f.write(s)
    f.close()

    return {'FINISHED'}

class ExportSomeData(Operator, ExportHelper):
    """This appears in the tooltip of the operator and in the generated docs"""
    bl_idname = "export_test.some_data"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Some Data"

    # ExportHelper mixin class uses this
    filename_ext = ".s3D"

    filter_glob: StringProperty(
        default="*.s3D",
        options={'HIDDEN'},
        maxlen=255,  # Max internal buffer length, longer would be clamped.
    )

    # List of operator properties, the attributes will be assigned
    # to the class instance from the operator settings before calling.
    use_setting: BoolProperty(
        name="Example Boolean",
        description="Example Tooltip",
        default=True,
    )

    type: EnumProperty(
        name="Example Enum",
        description="Choose between two items",
        items=(
            ('OPT_A', "First Option", "Description one"),
            ('OPT_B', "Second Option", "Description two"),
        ),
        default='OPT_A',
    )

    def execute(self, context):
        meshes = []
        for obj in bpy.context.selected_objects:
            if obj.type == "MESH":
                meshes.append(obj)
        
        scene_applied_mods = bpy.context.evaluated_depsgraph_get()

        print(meshes)
        for obj in meshes:
          mesh = obj.evaluated_get(scene_applied_mods).to_mesh()

          bm = bmesh.new()
          bm.from_mesh(mesh)

          bmesh.ops.triangulate(bm, faces=bm.faces)

          bm.to_mesh(mesh)

          indices = []
          vertices = []

          s: str = ""

          for poly in mesh.polygons:
              if len(poly.loop_indices) == 3:
                  for loop_index in poly.loop_indices:
                      loop = mesh.loops[loop_index]
                      position = mesh.vertices[loop.vertex_index].undeformed_co
                      s = s + str(position) + str(loop) + "\n" 
            
        
        return write_some_data(context, self.filepath, self.use_setting, s)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportSomeData.bl_idname, text="Export Custom (.s3D)")

# Register and add to the "file selector" menu (required to use F3 search "Text Export Operator" for quick access)
def register():
    bpy.utils.register_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.export_test.some_data('INVOKE_DEFAULT')
