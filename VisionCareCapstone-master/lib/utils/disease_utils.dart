// Add this utility function to help with disease key mapping
String getDiseaseKey(String diseaseName) {
  // Convert to lowercase and trim any extra spaces
  final String normalizedName = diseaseName.toLowerCase().trim();
  
  // Map of disease names to their standardized keys
  final Map<String, String> diseaseKeyMap = {
    'mild': 'mild',
    'moderate': 'moderate',
    'no_dr': 'no_dr',
    'proliferative': 'proliferative',
    'severe': 'severe',
    'normal': 'normal',
    'gray leaf spot': 'gray_leaf_spot',
    'grey leaf spot': 'gray_leaf_spot',
    'common rust': 'common_rust',
    'northern leaf blight': 'northern_leaf_blight',
    'healthy': 'healthy',
    // Add more mappings as needed
  };
  
  // Check if the disease name is in our map
  for (final entry in diseaseKeyMap.entries) {
    if (normalizedName.contains(entry.key)) {
      return entry.value;
    }
  }
  
  // Default fallback: replace spaces with underscores
  return normalizedName.replaceAll(' ', '_');
}