class_name QCCompileTemplates extends Node

static var arms_compile: String = '
$modelname "models/[author_plz]/[pm_2_plz]/[pm_2_plz]_arms.mdl"

$bodygroup "arms"
{
	studio "[pm_2_plz]_arms"
}

$surfaceprop "[replace_material]"

$contents "solid"

$illumposition -0.637 0 35.954

$eyeposition 0 0 65

$ambientboost

$mostlyopaque

$cdmaterials "models/[author_plz]/[pm_2_plz]/"

$cbox 0 0 0 0 0 0

$bbox -13 -13 0 13 13 72

//$proceduralbones "arms.vrd"

//definebones go here
//replaceplz//

$includemodel "f_anm.mdl"
$includemodel "f_anm.mdl"
$includemodel "f_gst.mdl"
$includemodel "f_pst.mdl"
$includemodel "f_shd.mdl"
$includemodel "f_ss.mdl"
$includemodel "humans/female_shared.mdl"
$includemodel "humans/female_ss.mdl"
$includemodel "humans/female_gestures.mdl"
$includemodel "humans/female_postures.mdl"
$includemodel "alyx_animations.mdl"
$includemodel "alyx_postures.mdl"
$includemodel "alyx_gestures.mdl"
$includemodel "humans/female_shared.mdl"
$includemodel "humans/female_ss.mdl"
'

static var pm_compile = '
$modelname "models/[author_plz]/[pm_2_plz]/[pm_2_plz].mdl"

//replacewithbodygroupstuff//

$surfaceprop "[replace_material]"

[texture_group_plz]

$contents "solid"

$illumposition -0.637 0 35.954

$ambientboost

$mostlyopaque

$cdmaterials "models/[author_plz]/[pm_2_plz]/"

$cbox 0 0 0 0 0 0

$bbox -13 -13 0 13 13 72

//replacewithbonephsicsstuff//

// define bones
//replaceplz//

$ikchain "rhand" "ValveBiped.Bip01_R_Hand" knee 0.707 0.707 0
$ikchain "lhand" "ValveBiped.Bip01_L_Hand" knee 0.707 0.707 0
$ikchain "rfoot" "ValveBiped.Bip01_R_Foot" knee 0.707 -0.707 0
$ikchain "lfoot" "ValveBiped.Bip01_L_Foot" knee 0.707 -0.707 0

$ikautoplaylock "rfoot" 0.5 0.1
$ikautoplaylock "lfoot" 0.5 0.1

//Rename reference_male to reference_female if you\'re using female pm/npc animation
$sequence reference "anims/reference_[replace_gender]" fps 1

$animation a_proportions "anims/proportions" subtract reference 0

$sequence proportions a_proportions predelta autoplay

$Sequence "ragdoll" {
	"anims/proportions"
	activity "ACT_DIERAGDOLL" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}

$includemodel "f_anm.mdl"
$includemodel "f_anm.mdl"
$includemodel "f_gst.mdl"
$includemodel "f_pst.mdl"
$includemodel "f_shd.mdl"
$includemodel "f_ss.mdl"
$includemodel "humans/female_shared.mdl"
$includemodel "humans/female_ss.mdl"
$includemodel "humans/female_gestures.mdl"
$includemodel "humans/female_postures.mdl"
$includemodel "alyx_animations.mdl"
$includemodel "alyx_postures.mdl"
$includemodel "alyx_gestures.mdl"
$includemodel "humans/female_shared.mdl"
$includemodel "humans/female_ss.mdl"

$collisionjoints "pm_physics.smd"
{
	$mass [mass]
	$inertia [inertia]
	$damping [damping]
	$rotdamping [rotdamping]
	$rootbone "ValveBiped.Bip01_Pelvis"
	$concave

	$jointconstrain "valvebiped.bip01_spine" x limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_spine" y limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_spine" z limit -20.00 10.00 0.00

	$jointconstrain "valvebiped.bip01_spine1" x limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_spine1" y limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_spine1" z limit -20.00 10.00 0.00

	$jointconstrain "valvebiped.bip01_spine2" x limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_spine2" y limit -15.00 15.00 0.00
	$jointconstrain "valvebiped.bip01_spine2" z limit -30.00 45.00 0.00

	$jointconstrain "valvebiped.bip01_spine4" x limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_spine4" y limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_spine4" z limit -20.00 10.00 0.00

	$jointconstrain "valvebiped.bip01_r_clavicle" x limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_r_clavicle" y limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_r_clavicle" z limit -5.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_l_clavicle" x limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_l_clavicle" y limit -20.00 20.00 0.00
	$jointconstrain "valvebiped.bip01_l_clavicle" z limit -5.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_l_upperarm" x limit -45.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_l_upperarm" y limit -45.00 50.00 0.00
	$jointconstrain "valvebiped.bip01_l_upperarm" z limit -90.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_l_forearm" x limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_l_forearm" y limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_l_forearm" z limit -130.00 0.00 0.00

	$jointconstrain "valvebiped.bip01_l_hand" x limit -45.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_l_hand" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_l_hand" z limit -30.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_r_upperarm" x limit -45.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_r_upperarm" y limit -50.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_r_upperarm" z limit -90.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_neck1" x limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_neck1" y limit -15.00 15.00 0.00
	$jointconstrain "valvebiped.bip01_neck1" z limit -20.00 20.00 0.00

	$jointconstrain "valvebiped.bip01_r_forearm" x limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_r_forearm" y limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_r_forearm" z limit -130.00 0.00 0.00

	$jointconstrain "valvebiped.bip01_r_hand" x limit -45.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_r_hand" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_r_hand" z limit -30.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_r_thigh" x limit -15.00 15.00 0.00
	$jointconstrain "valvebiped.bip01_r_thigh" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_r_thigh" z limit -60.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_r_calf" x limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_r_calf" y limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_r_calf" z limit 0.00 110.00 0.00

	$jointconstrain "valvebiped.bip01_head1" x limit -45.00 45.00 0.00
	$jointconstrain "valvebiped.bip01_head1" y limit -10.00 10.00 0.00
	$jointconstrain "valvebiped.bip01_head1" z limit -15.00 15.00 0.00

	$jointconstrain "valvebiped.bip01_l_thigh" x limit -15.00 15.00 0.00
	$jointconstrain "valvebiped.bip01_l_thigh" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_l_thigh" z limit -60.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_l_calf" x limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_l_calf" y limit 0.00 0.00 0.00
	$jointconstrain "valvebiped.bip01_l_calf" z limit 0.00 110.00 0.00

	$jointconstrain "valvebiped.bip01_l_foot" x limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_l_foot" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_l_foot" z limit -30.00 30.00 0.00

	$jointconstrain "valvebiped.bip01_r_foot" x limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_r_foot" y limit -30.00 30.00 0.00
	$jointconstrain "valvebiped.bip01_r_foot" z limit -30.00 30.00 0.00
}
'
