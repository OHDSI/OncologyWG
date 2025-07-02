# Metastasis Mapping Logic 
This guidance describes how to map source terms that mention metastases to standard concepts in OHDSI Standardized Vocabularies, using: 

**SNOMED CT (or ICD-O-3 when no appropriate term in SNOMED CT)** for the neoplasm/histology axis (Condition domain) 

	AND 
    
**Cancer Modifier** Metastasis concepts for the metastasis axis (Measurement domain). 

**Goal:** Create mappings that are as specific as the source allows but never add information that is not present. 

**Default rules of thumb:**  
1) Represent the metastatic aspect with a Cancer Modifier **only(!)**.  
2) Represent the topography aspect with the destination-specific Cancer Modifier metastasis concept;
   
Terminology used in the rules:

**Primary neoplasm** - the anatomic site where the malignant neoplasm first arose. 

**Secondary neoplasm / metastasis** - a tumor deposit located at a distant, non-contiguous site relative to the primary tumor. 

**Direction of metastasis** - phrases such as “to <site>” (destination site), “from <site>” (primary site), “of unknown primary” (unknown site). 

**Histology**  - the source explicitly states a morphology of a neoplasm (e.g., “adenocarcinoma”, “squamous-cell carcinoma”) 

**Topography / localization** - the anatomic location referenced in the term. Two flavors: 
* Primary topography - the site of origin of malignant neoplasm. 
* Metastatic (destination) topography - the site to which the cancer has spread. 

## Mapping algorithm  

| # | Rule description | Mapping strategy | Example(s) | Notes |
|---|---|---|---|---|
| R1 | Generic “Metastatic cancer” or “Metastatic malignant neoplasm” **with no further detail** (no histology + no topography + no destination known) | Map to generic SNOMED Condition concept “Malignant neoplastic disease” + Cancer Modifier “Metastasis” concept. | Metastatic malignant neoplasm → 443392 Malignant neoplastic disease (SNOMED Condition) + 36769180 Metastasis (Cancer Modifier Measurement) | Use when it is unclear whether the term refers to a primary or a secondary tumor. |
| R2 | Source specifies **direction / destination only** (usually have **“to <site>”** but not always) | Map only to destination-specific Cancer Modifier | 1) Metastasis to bone → 36769301 Metastasis to bone (Cancer Modifier Measurement) <br> 2) Malignant blood vessel neoplasm, metastatic → 35226042 Metastasis to blood vessel (Cancer Modifier Measurement) | If no granular Cancer Modifier exists, fall back to plain Metastasis. |
| R3 | Source gives **histology + “metastatic” + destination site** (“Metastatic adenocarcinoma to skin”) | Map histology part to SNOMED Condition. When no exact histologic match exists, map to the nearest higher-level (less specific) SNOMED concept or apply R5. Map metastasis to destination-specific Cancer Modifier. If no granular Cancer Modifier exists, fall back to plain Metastasis. | Metastatic adenocarcinoma to skin → 40484156 Malignant adenomatous neoplasm (SNOMED Condition) + 35225673 Metastasis to skin (Cancer Modifier Measurement) | Couple the histology with the primary topography if it is explicitly stated in the source; otherwise drop the topography from the neoplasm side and keep it only in the modifier. When no exact histologic match exists, map to the nearest higher-level (less specific) SNOMED concept or apply R5. If no granular Cancer Modifier exists, fall back to plain Metastasis. |
| R4 | Source specifies **histology + “metastatic”** and no destination | Map to SNOMED histology concept (Condition domain) **AND** plain Cancer Modifier Metastasis. | Metastatic squamous-cell carcinoma → 4300118 Squamous cell carcinoma (SNOMED Condition) + 36769180 Metastasis (Cancer Modifier Measurement) | The unspecified metastasis modifier conveys secondary nature. |
| R5 | Source gives **histology + “metastatic”**, but available SNOMED histology concept is not granular enough | Prefer the closest ICD-O-3 code if one exists and histology precision is critical; otherwise map one level up in SNOMED (to more generic concept); **PLUS,** Cancer Modifier Metastasis. | Metastatic papillary squamous cell carcinoma → 42513034 Neoplasm defined only by histology: Papillary squamous cell carcinoma (ICDO3 Condition) + 36769180 Metastasis (Cancer Modifier Measurement) | |
| R6 | Source gives **histology + primary topography + “metastatic”** (but no explicit destination site) | If SNOMED offers a combined concept (histology + topography) use it, plus map to Cancer Modifier Metastasis. If not - apply R4. | Metastatic non-small cell lung cancer → 4115276 Non-small cell lung cancer (SNOMED Condition) + 36769180 Metastasis (Cancer Modifier Measurement) | - |
| R7 | A destination site **exists in reality but has no dedicated Cancer Modifier concept** (e.g. nipple which is male OR female, and no generic one) | Map to the nearest available destination modifier (‘Metastasis to breast’) only and accept the generalization. | Metastatic malignant neoplasm to nipple → 35225556 Metastasis to breast (Cancer Modifier Measurement) | |
| R8 | **Multiple destination sites** in one term | Map to several Metastasis modifiers per each destination site | Metastasis to large intestine and rectum → 35225543 Metastasis to large intestine (Cancer Modifier Measurement) + 35226275 Metastasis to rectum (Cancer Modifier Measurement) | - |
| R9 | Term says **“…of unknown primary/unknown site”** | Map to SNOMED ‘Primary malignant neoplasm of unknown site’ if histology is not mentioned (1) OR to ICD-O-3 “<histology> NOS, of unknown primary site” (2) + Cancer Modifier Metastasis concept. | 1) Metastasis to adrenal gland of unknown primary → 4149322 Primary malignant neoplasm of unknown site (SNOMED Condition) + 35225568 Metastasis to adrenal gland (Cancer Modifier Measurement) <br> 2) Metastatic adenocarcinoma of unknown origin → 36402366 Adenocarcinoma, NOS, of unknown primary site (ICD-O-3 Condition) + 35225568 Metastasis to adrenal gland (Cancer Modifier) | |
| R10 | **Source specifies “Metastasis to lymph node(s)”** | Use SNOMED for histology (if any) and add the canonical modifier “Spread to lymph node” (not “Metastasis”-to-site). | Metastasis to lymph node from adenocarcinoma → 40484156 Malignant adenomatous neoplasm (SNOMED) + 36768587 Spread to lymph node (Cancer Modifier) | Aligns with AJCC/SEER semantics; preserves analytic cohorts for nodal vs distant spread. |
| R11 | The source term describes a generic malignant neoplasm with **bilateral metastases to a paired organ** but does not state histology or primary topography. | Create two Cancer Modifier maps - one for each side (right and left). | Bilateral metastatic malignant neoplasm to adrenal glands → 35225626 Metastasis to left adrenal gland (Cancer Modifier) + 35226288 Metastasis to right adrenal gland | - |
| R12 | The term gives a **primary topography + “disseminated”** without naming metastatic destinations. | Assign the SNOMED concept “Primary malignant neoplasm of [primary site]” + add the plain Metastasis modifier. | Ovarian cancer, disseminated → 200051 Primary malignant neoplasm of ovary (SNOMED) + 36769180 Metastasis (Cancer Modifier) | - |
| R13 | Source states the **primary topography** and explicitly names the **destination topography** (“X cancer metastatic to Y”). | Map the tumor to “Primary malignant neoplasm of [primary site]” + add the destination-specific Cancer Modifier (“Metastasis to [destination]”). If that modifier does not exist, roll up to plain Metastasis. | Prostate cancer metastatic to bone → 200962 Primary malignant neoplasm of prostate (SNOMED) + 36769301 Metastasis to bone (Cancer Modifier) | - |
| R14 | ICD-O-3 source codes contain information about **/6 - pathology-confirmed metastatic origin** and primary topography code after hyphen | Map histology part to SNOMED Condition with histology and primary topography + plain Cancer Modifier Metastasis | 1) 8140/6-C50.9 Adenocarcinoma, metastatic, NOS, of breast, NOS → 3655521, Adenocarcinoma of breast (SNOMED Condition) + 36769180 Metastasis (Cancer Modifier Measurement) <br> 2) Adenocarcinoma, metastatic, NOS, of stomach, NOS → 4248802, Adenocarcinoma of stomach (SNOMED Condition) + 36769180 Metastasis (Cancer Modifier Measurement) <br> Exceptions: 8140/6-C41.9 Adenocarcinoma, metastatic, NOS, of bone, NOS <br> 8140/6-C71.9 Adenocarcinoma, metastatic, NOS, of brain, NOS | - |
