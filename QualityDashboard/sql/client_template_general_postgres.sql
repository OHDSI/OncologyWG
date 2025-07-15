
/***************************************************************************
Lab tests relevant to eligibility assessment of common antineoplastic agents
***************************************************************************/
drop table if exists test;
create temp table test(
  measurement_concept_id int
);

-- 1. ECOG
insert into test values (3031531), (1030477), (36305299), (36305384), (45876440), (36303470), (4167763), (4173614), (4172043), (4174241), (4174251), (4173456), (4308014), (4175026), (4308794);
-- 2. Karnofsky
insert into test values (35917688), (35933979), (40358000), (4169154), (42538353), (42539319), (35917941), (35931215), (1017885), (44812126), (3566792), (3548023), (3546564), (44812129), (44812133), (36303287), (36304284), (36303744), (3573899);
-- 3. NYHA
insert into test values (1017401), (1002237), (40297916), (35621756), (40544925), (3574337), (3574338), (3574339), (3576434), (35621760), (4223299), (40581213), (40581214), (40581215), (40581216), (40544928), (35609695), (35609696), (36305765), (36304558), (1027960), (3571603), (3523269), (4220607), (4227345), (4226789), (4228881), (3576336), (3523013);
-- 4. Charlson
insert into test values (42538860), (715970);
-- 5. GFR
insert into test values (40478963), (40483219), (40485075), (4055802), (4042226), (3043621), (1617023), (37393011), (37393012), (37208635), (3557182), (44808279), (3559661), (46285137), (3561268), (3561269), (1008434), (40769275), (44806420), (37393690), (37399046), (42235776), (4338520), (45766361), (1029770), (4213477), (3577339), (3577386), (3523671), (759544), (759545), (600814), (3655421), (37169597), (37168979), (44788275), (3552636), (3552918), (44790060), (3554521), (3554357), (42537612), (44514146), (3554610), (44790183), (37174826), (1018491), (37075065), (36033091), (37077746), (37030256), (37068907), (37078272), (37052213), (37041591), (36033624), (37045756), (37041188), (37055720), (3030354), (40771922), (1619026), (36660257), (3965919), (1619025), (40764999), (46236952), (3030104), (3029859), (36031320), (36306178), (3053283), (3029829), (42869913), (36031846), (36303797), (3049187), (46235172), (36662614), (1619800), (1618558), (46236975), (40478895), (40771924), (1010106), (37061620), (37027780), (37024736), (37033687), (44792172), (45768505), (42364981), (42785722), (42783791), (42791039), (42786462), (42787952), (4346613);
-- 6. ANC
insert into test values (36769650), (3014725), (3017354), (3018199), (3004809), (3017161), (3008939), (3007591), (46235906), (3027270), (3028108), (1989444), (37022438), (37043639), (37048254), (37033438), (37392144), (3041311), (3010686), (37030238), (4198194), (40324175), (4187371), (3559287), (21495726), (21496442), (21498095), (21498093), (4097612), (3035839), (40768821), (43055338), (43055343), (36659806), (36659925), (4015164), (4015165), (35609608), (4002885), (43055363), (40792738), (45765692), (45765909), (45765910), (45766355), (3559251), (3559252), (3012608), (3001465), (3023500), (3015586), (3019355), (3022005), (3045469), (3032632), (40782560), (37398605), (4133825), (1988450), (40481861), (36714460), (44807941), (40302436);
-- 7. Platelets 
insert into test values (440372), (40359195), (2212657), (4172008), (4295441), (4105080), (4271176), (4196335), (37054046), (21497408), (37073482), (46235211), (37081809), (42485805), (45537930), (1567864), (45542714), (37606159), (44819531), (45576412), (44820703), (3567546), (4098768), (4098149), (3557991), (766345), (44826483), (441264), (3558008), (4150155), (44824101), (42872952), (36715586), (4133983), (35206771), (37081812), (45532995), (37605925), (40321716), (42485806), (44831071), (40390864), (3557879), (4146091), (37081819), (40624797), (766004), (35918846), (40301839), (40332931), (44782445), (4098148), (37018663), (4173278), (3661632), (4219476), (4301128), (4147049), (4101603), (4272928), (4145458), (4338386), (40607602), (4156233), (38000031), (40321717), (4101604), (3557992), (35919838), (35919264), (40390494), (37612610), (42485807), (35206772), (37081820), (45581327), (44825284), (4226905), (4280071), (766344), (45528892), (766346), (40390986), (44795907), (1033653), (40779159), (3955946), (36310193), (40786570), (44787167), (37071943), (37037425), (40654106), (40654107), (40654108), (37045092), (3050583), (37044407), (37058547), (1092269), (3007461), (3024929), (1616298), (3031586), (3010834), (40765005), (44787107), (3006297), (3016682), (35919264);
-- 8. Hemoglobin 
insert into test values (3034666), (3955933), (45889912), (40795725), (4038953), (4013074), (40789986), (40793300), (40787384), (40793915), (40774048), (40301220), (4013075), (4013401), (40301218), (4049428), (4226695), (40301221), (40332329), (37037081), (40784444), (2106864), (4153000), (2106862), (2106867), (40301217), (3030854), (3002173), (3006239), (3027901), (3029461), (3000963), (3027484), (40758903), (40757420), (40763941), (3048275), (3006184), (1616317), (1617122), (1617021), (3003675), (3007302), (1091111), (46235391), (3004119), (1091321), (46235392), (21490721), (40762351), (1092194), (1002216), (1259766), (3040522), (40301219), (40786237), (2212396), (3005872), (45889532), (40301223), (4013837), (40301216), (4013073), (4013836), (40286212), (40480067), (4288754), (4015178), (4016242), (40484519), (43533195), (43533230), (40664705), (40664666);
-- 9. Creatinine
insert into test values (37398464), (40328935), (40307223), (4195331), (40307224), (37392198), (40328936), (4197967), (42357141), (42357149), (45888378), (35814434), (40775801), (1021276), (37079906), (40796376), (2212294), (40793622), (4077513), (3552485), (37394438), (3552681), (4275203), (3032033), (3007760), (3051825), (3016723), (4324383), (4013964), (40762887), (3020564), (3041735), (1260102), (46235076), (3964702), (19688918), (42086413), (42349688), (2212295), (35917168), (3035064), (40307226), (40328938), (37392200), (4199025), (4041902), (4055579), (40307212), (40328452), (37392176), (4276437), (3557578), (4055580), (4042574), (4042575), (8683);
-- 10. CrCl
insert into test values (40761547), (3044031), (37068680), (2212296), (3655422), (1011112), (42869901), (40354584), (40308899), (4253380), (40308904), (37393360), (40330755), (45532639), (37071451), (4010651), (37047104), (3007659), (3027108), (3034605), (3022053), (3025137), (3026583), (3035532), (37044930), (37058458), (3032720), (37078988), (37041867), (3029545), (37060719), (3033962), (37075417), (37034723), (37038087), (37071858), (3006873), (37208556), (3005770), (3022988), (3018252), (3018775), (3004917), (3047148), (4019552), (37076262), (37044136), (1091718), (37027339), (3035529), (37045863), (1094424), (37024397), (3006240), (37205200), (37169169), (37169171), (37169170), (3561311), (46285249), (40483173), (4042762);
-- 11. Total bilirubin
insert into test values (45890528), (40779224), (40796605), (40778755), (37073886), (1618049), (37046070), (40795310), (37030091), (4094445), (3043744), (3043995), (44788714), (40789192), (40788343), (40798220), (37064590), (40652706), (40654437), (37028490), (37051609), (40794914), (40654438), (37027562), (4076936), (3558550), (4094532), (4050611), (4269845), (4118986), (37038273), (37029216), (2212226), (37064827), (3032945), (40762888), (3028833), (3024128), (40762889), (40353086), (4230543), (37151723), (37151727), (1175183), (40757494), (1616780), (3006140), (46235782), (1175191), (37398233), (40328351), (40315336), (4210860), (4043078), (4041184), (40315333), (40483568), (40483184), (40354563), (40315326), (37398424), (4269846), (4041529), (40315328), (40315342), (4041186), (3557609), (40315329), (4043077), (40328355), (37399653), (40315340), (4195338), (35814530), (45757521), (40315330), (40328347), (37394117), (37208619), (37208618);
-- 12. Direct bilirubin 
insert into test values (3019676), (3005772), (2212227), (3032335), (3027597), (37398377), (3558502), (4216632), (3028638), (3043347), (40775879), (40783493), (37027118), (37392379), (3558551), (40315331), (44805650), (37208552), (37208553), (4245547), (3018682), (3021680), (35814406), (3655423), (3558503), (37394191), (40328350), (40315335), (37398232), (4195339), (40328354), (37398235), (40315339), (4198887);
-- 13. AST 
insert into test values (36033545), (4094595), (3013721), (3010587), (4263457), (44810795), (40315384), (40315385), (40462064), (4041190), (4043085), (4042568), (37174764), (4189605), (2212597), (36031681), (40785861), (37059000), (37392189), (37398463), (37208512), (37208565), (4197974), (35814399), (40328399), (40328409), (40328410), (36305398), (3956411), (40315377), (40787003), (3037081), (40652640), (45531649), (37394375);
-- 14. ALT
insert into test values (46235106), (46236949), (40652525), (36033592), (37393142), (37393531), (44788835), (3554167), (3554168), (3955919), (4042564), (4041531), (37174713), (40779048), (37151648), (3015912), (3019056), (37071721), (37047736), (37074219), (45525616), (4019440), (4018061), (37208490), (37208513), (37070195), (4146380), (40328375), (40563834), (40558873), (1247076), (40796722), (4249568), (2212598), (3006923), (3005755), (3027388), (3022893), (40782579), (4096233), (4095055), (4190899), (44810789), (35814378), (40315359), (40315363), (40462059);
-- 15. INR 
insert into test values (40785749), (40787533), (40790995), (40784503), (3042605), (37074906), (44792519), (44793006), (4306239), (3556189), (3528525), (3556226), (3528565), (3556342), (3556343), (3546057), (3559950), (44810004), (37174852), (3051593), (35917345), (35927368), (37042344), (37061141), (37057823), (37072728), (3022217), (4306576), (4306577), (45757550), (3032080), (35918755), (4196718), (3039326), (4261078), (40301860);
-- 16. PTT
insert into test values (40788142), (40788269), (40781659), (40798144), (3053181), (40792548), (45532440), (45532704), (4306444), (4306445), (4306269), (4213658), (42710021), (2212731), (3033891), (3034426), (3002417), (37044890), (37070720), (37041470), (37051085), (37043621), (4245261), (44809199), (40787645), (40794295), (40794336), (45889638), (4260197), (3559030), (40645225);
-- 17. aPTT
insert into test values (44809202), (40301851), (40775569), (40792130), (40792133), (40785560), (40792131), (40772301), (3041944), (40778897), (40775918), (21497369), (37037324), (21497432), (21496554), (37022168), (37043668), (21497370), (37067246), (3016529), (3013466), (3010800), (3016290), (3038102), (3018677), (3031305), (37032508), (37075315), (21495977), (37041593), (3009363), (3000944), (3551002), (3576046), (40575044), (4175016), (607645), (4249569);
-- 18. HbA1c
insert into test values (40478875), (36033143), (40758583), (3035097), (2617505), (2617506), (40654761), (45765893), (1029009), (35814469), (3956570), (3557553), (37392407), (3556806), (37398434), (37173523), (37392408), (37170188), (40302402), (40302401), (40302400), (40302404), (4306439), (37171451), (40333052), (40302398), (44793001), (37208641), (724434), (40324145), (40302403), (37393623), (3556272), (3556271), (4197971), (40779306), (40797575), (42236090), (42363150), (42359964), (42236091), (40789263), (42335746), (42338757), (42341735), (42344940), (42349751), (764124), (4306587), (40775446), (42363144), (42360997), (42335718), (42338718), (42341815), (42344932), (42349676), (4276582), (42335885), (42335889), (42335758), (42335400), (19688978), (42338928), (42086333), (42338568), (42338868), (19688976), (42086356), (42341745), (42341767), (42342037), (19688975), (42344961), (42345168), (42344652), (42344959), (19688974), (4306250), (764125), (37056065), (1017437), (36304734), (3004410), (3007263), (3005673), (40762352), (40765129), (36032094), (1621295), (42869630), (4306438), (40307813), (40329569), (3034639), (4184637), (3033145), (42349915), (42349981), (42349928), (42349808), (19688979), (37174831), (37024125), (3005446), (40329570), (40307814), (4147407), (1018498), (2212392), (2212393), (40480694), (1133964), (1133965), (1133966), (1552826), (2106238), (40217293), (709959), (709960), (2106236), (42741295), (2106252), (40483736), (9225);
-- 19. PD-L1
insert into test values (1094398), (1094317), (1094232), (1094063), (718584), (37049248), (37049330), (37069580), (1991653), (1988568), (1091989), (718585), (718589), (718588), (718586), (718587), (42527892), (42527893), (42527894), (42529558), (42529561), (42529176), (1093941), (42529657), (42529788), (42530322), (42529560), (42529175), (37057475), (37071531), (37022030), (1990806), (1094163), (1092026), (1133877), (1133879), (1133878), (724582), (37164163), (37154038), (1092047), (1091860), (36031613), (42529559), (42529956);

-- Adding the lab test concepts to the overall list of concepts to count
insert into concepts
select measurement_concept_id as concept_id
from test
left join concepts on measurement_concept_id = concept_id
where concept_id is null;

/************************************************************************************
Creating complete list of source and standard concept pairs and their absolute counts
In addition, distribution of values for select lab tests
No patient-level information is captured
************************************************************************************/
-- the first date in the clinical event tables
with a as (
  select min(drug_exposure_start_date) as min_date from @cdm_schema.drug_exposure
  union select min(condition_start_date) from @cdm_schema.condition_occurrence
  union select min(procedure_date) from @cdm_schema.procedure_occurrence
  union select min(device_exposure_start_date) from @cdm_schema.device_exposure
  union select min(observation_date) from @cdm_schema.observation
  union select min(measurement_date) from @cdm_schema.measurement
),
-- the last date in the clinical event tables
b as (
  select max(drug_exposure_end_date) as max_date from @cdm_schema.drug_exposure
  union select max(condition_end_date) from @cdm_schema.condition_occurrence
  union select max(procedure_date) from @cdm_schema.procedure_occurrence
  union select max(device_exposure_end_date) from @cdm_schema.device_exposure
  union select max(observation_date) from @cdm_schema.observation
  union select max(measurement_date) from @cdm_schema.measurement
),
-- Distribution of lab test results as 3rd, 25th, median, 75th and 97th percentile
-- Max and min values are often outliers, 3rd and 97th is used instead
lab_values as (
  select measurement_concept_id, unit_concept_id, range_low,
  range_high, value_as_concept_id,
  percentile_cont(0.03) within group (order by value_as_number) as p_03,
  percentile_cont(0.25) within group (order by value_as_number) as p_25,
  percentile_cont(0.5) within group (order by value_as_number) as median,
  percentile_cont(0.75) within group (order by value_as_number) as p_75,
  percentile_cont(0.97) within group (order by value_as_number) as p_97,
  count(value_as_number) as cnt
  from (
    select measurement_concept_id, unit_concept_id, range_low,
    range_high, value_as_concept_id, value_as_number
    from @cdm_schema.measurement
    join test using(measurement_concept_id)
	where value_as_number!=0 and value_as_number is not null
    union all
    select observation_concept_id, unit_concept_id, null as range_low, 
    null as range_high, value_as_concept_id, value_as_number
    from @cdm_schema.observation
    join test on observation_concept_id=measurement_concept_id
	where value_as_number!=0 and value_as_number is not null
  ) c
  group by measurement_concept_id, unit_concept_id, range_low,
  range_high, value_as_concept_id
)
-- Total patient count in the database
select 't' as domain, null as source, null as standard, count(*) as cnt, null as measurement
from @cdm_schema.person
union
-- The very first start date and the very last end dates across all domains
select 'w' as domain,
min(a.min_date)-date('2000-01-01') as source, 
max(b.max_date)-date('2000-01-01') as standard,
null as cnt, null as measurement
from a, b
union
-- First and last day of any observation period
select 'b' as domain,
min(observation_period_start_date)-date('2000-01-01') as source, 
max(observation_period_end_date)-date('2000-01-01') as standard, 
null as cnt, null as measurement
from @cdm_schema.observation_period
union
-- Source and standard drug concept counts
select 'd' as domain, drug_source_concept_id, drug_concept_id, count(*) as cnt, null as measurement
from (
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_source_concept_id
union
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_concept_id
) a
join @cdm_schema.drug_exposure using(drug_exposure_id)
group by drug_source_concept_id, drug_concept_id
union
-- Source and standard device concept counts
select 'e' as domain, device_source_concept_id, device_concept_id, count(*) as cnt, null as measurement
from (
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_source_concept_id
union
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_concept_id
) a
join @cdm_schema.device_exposure using(device_exposure_id)
group by device_source_concept_id, device_concept_id
union
-- Source and standard procedure concept counts
select 'p' as domain, procedure_source_concept_id, procedure_concept_id, count(*) as cnt, null as measurement
from (
  select procedure_occurrence_id
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_source_concept_id
union
  select procedure_occurrence_id 
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_concept_id
) a
join @cdm_schema.procedure_occurrence using(procedure_occurrence_id)
group by procedure_source_concept_id, procedure_concept_id
union
-- Source and standard condition concept counts
select 'c' as domain, condition_source_concept_id, condition_concept_id, count(*) as cnt, null as measurement
from (
  select condition_occurrence_id 
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_source_concept_id
union
  select condition_occurrence_id
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_concept_id
) a
join @cdm_schema.condition_occurrence using(condition_occurrence_id)
group by condition_source_concept_id, condition_concept_id
union
-- Source and standard observation concept counts
select 'o' as domain, observation_source_concept_id, observation_concept_id, count(*) as cnt, null as measurement
from (
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_source_concept_id
union
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_concept_id
) a
join @cdm_schema.observation using(observation_id)
group by observation_source_concept_id, observation_concept_id
union
-- Source and standard measurement concept counts
select 'm' as domain, measurement_source_concept_id, measurement_concept_id, count(*) as cnt, null as measurement
from (
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_source_concept_id
union
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_concept_id
) a
join @cdm_schema.measurement using(measurement_id)
group by measurement_source_concept_id, measurement_concept_id
union
-- Measurement value concept counts
select 'v' as domain, null, value_as_concept_id, count(*) as cnt, null as measurement
from @cdm_schema.measurement
join concepts on concept_id=value_as_concept_id
group by value_as_concept_id
union
-- Lab value distribution as string for transport purposes
select 'l' as domain, measurement_concept_id, unit_concept_id, value_as_concept_id,
coalesce(cast(range_low as text), '') || '~' || 
coalesce(cast(range_high as text), '') || '~' ||
coalesce(cast(p_03 as text), '') || '~' ||
coalesce(cast(p_25 as text), '') || '~' ||
coalesce(cast(median as text), '') || '~' ||
coalesce(cast(p_75 as text), '') || '~' ||
coalesce(cast(p_97 as text), '') || '~' ||
coalesce(cast(cnt as text), '')
as measurement
from lab_values
;
