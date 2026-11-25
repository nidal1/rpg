extends Skill
class_name AttackSkill

enum TargetType {
	enemy,
	aoe,
}

# STUN (صعق / شلل): حالة كتمنع العدو نهائياً من الحركة، الهجوم، أو استعمال أي سكيل لفترة قصيرة جداً (مثلاً 2 أو 3 ثواني)، وكيتعتبر من أخطر أنواع التحكّم فـ PvP.

# SILENCE (إسكات): حالة كتمنع الكلاسات السحرية (Mages/Priests) من إطلاق أي سكيل أو تعويذة سحرية، وكتخليهم يقدروا يديروا غير الهجوم العادي (Auto-Attack).

# ROOT أو BIND (تثبيت فالمكان): كتمنع العدو من الحركة أو الجري (ما يقدرش يبدل بلاصتو)، ولكن كتبقي ليه الصلاحية باش يضرب بالعصا أو يطلق سحورات وهو واقف في بلاصته.

# BLEEDING (نزيف): نوع من الضرر الجسدي المستمر (Physical DoT - Damage over Time) كيبقى ينقص من الدم (HP) تدريجياً كل ثانية بسبب ضربة سلاح حادة.

# BURN (احتراق): ضرر عنصري ناري مستمر (Magical DoT) كيبقى يأكل فصحة الهدف لفترة زمنية محددة.

# BLIND أو BLINDNESS (عمى مؤقت): حالة كتخفض نسبة الإصابة (Hit Rate / Accuracy) ديال العدو، وكيتخليه يضرب ضربات كتمشي فارغة (Miss) بزاف.

# SLOW (إبطاء السرعة): كينقص من سرعة الحركة (Movement Speed) وحتى سرعة الهجوم (Attack Speed) ديال العدو، وشفناه ديما مرتبط بعنصر الجليد أو المائي.

# FREEZE (تجميد): كيطور الـ Slow؛ كيحبس العدو كلياً فبلاكتو وكيمنعو من أي حركة أو فعل، ولكن غالباً يلا تلقى ضربة قوية كيتفك التجميد (مؤقت)

#Crowd Control Damage
enum CrowdControl {
	stun, #(صعق / شلل)
	silence, #(إسكات)
	bind, #(تثبيت فالمكان)
	bleeding,# (نزيف)
	burn, #(احتراق),
	blind, #(عمى مؤقت)
	slow, #(إبطاء السرعة),
	none
}

# targeting and range
@export var skill_target_type: TargetType = TargetType.enemy
@export var skill_range: float
@export var skill_distance: float

#Combat & Effects
@export var damage: Array[float] = []
@export var cc_effect: CrowdControl
@export var cc_duration: float
@export var active_scene_path: String

func can_cast_skill() -> bool:
	var player_has_enough_mp = StatsData.get_base_stat("MP") >= mp_cost
	if player_has_enough_mp : return true
	return false

func get_value() -> Dictionary:
	var idx = clampi(level - 1, 0, damage.size() - 1)
	#return damage[idx] if not damage.is_empty() else 0.0
	return {
		'value': damage[idx] if not damage.is_empty() else 0.0,
		'stat_type': "",
		"active_scene": load_active_scene()
	}

func load_active_scene():
	if active_scene_path:
		var inst = load(active_scene_path).instantiate()
		return inst
	
	return null
