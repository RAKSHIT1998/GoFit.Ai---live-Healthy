import SwiftUI

struct MedicalCitationsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("All health and nutritional calculations in this app are based on established scientific research and medical guidelines. Below are the sources for our recommendations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } header: {
                    Text("About Our Health Data")
                }
                
                Section {
                    CitationRow(
                        title: "BMR & TDEE Calculations",
                        description: "Mifflin-St Jeor Equation for Basal Metabolic Rate",
                        url: "https://pubmed.ncbi.nlm.nih.gov/2305711/"
                    )
                    
                    CitationRow(
                        title: "Activity Multipliers",
                        description: "Physical Activity Level Guidelines - WHO",
                        url: "https://www.who.int/news-room/fact-sheets/detail/physical-activity"
                    )
                    
                    CitationRow(
                        title: "Caloric Deficit/Surplus",
                        description: "Mayo Clinic - Weight Loss Guidelines",
                        url: "https://www.mayoclinic.org/healthy-lifestyle/weight-loss/in-depth/calories/art-20048065"
                    )
                } header: {
                    Text("Calorie Calculations")
                }
                
                Section {
                    CitationRow(
                        title: "Macro Distribution",
                        description: "USDA Dietary Guidelines for Americans",
                        url: "https://www.dietaryguidelines.gov/"
                    )
                    
                    CitationRow(
                        title: "Protein Requirements",
                        description: "Academy of Nutrition and Dietetics",
                        url: "https://www.eatright.org/food/nutrition/dietary-guidelines-and-myplate/protein"
                    )
                    
                    CitationRow(
                        title: "Carbohydrate Recommendations",
                        description: "American Diabetes Association",
                        url: "https://diabetes.org/healthy-living/recipes-nutrition/understanding-carbs"
                    )
                    
                    CitationRow(
                        title: "Healthy Fats",
                        description: "American Heart Association",
                        url: "https://www.heart.org/en/healthy-living/healthy-eating/eat-smart/fats"
                    )
                } header: {
                    Text("Macronutrient Guidelines")
                }
                
                Section {
                    CitationRow(
                        title: "Exercise Recommendations",
                        description: "CDC Physical Activity Guidelines",
                        url: "https://www.cdc.gov/physicalactivity/basics/adults/index.htm"
                    )
                    
                    CitationRow(
                        title: "Strength Training",
                        description: "American College of Sports Medicine",
                        url: "https://www.acsm.org/education-resources/trending-topics-resources/resource-library/resource_detail?id=4a40f1c0-975d-46a2-8c5e-1c8e9a9e3c3a"
                    )
                    
                    CitationRow(
                        title: "Cardiovascular Health",
                        description: "American Heart Association Exercise Guidelines",
                        url: "https://www.heart.org/en/healthy-living/fitness/fitness-basics/aha-recs-for-physical-activity-in-adults"
                    )
                } header: {
                    Text("Exercise & Fitness")
                }
                
                Section {
                    CitationRow(
                        title: "Water Intake Guidelines",
                        description: "National Academies of Sciences",
                        url: "https://www.nationalacademies.org/news/2004/02/report-sets-dietary-intake-levels-for-water-salt-and-potassium-to-maintain-health-and-reduce-chronic-disease-risk"
                    )
                    
                    CitationRow(
                        title: "Hydration for Athletes",
                        description: "American Council on Exercise",
                        url: "https://www.acefitness.org/education-and-resources/lifestyle/blog/112/fit-facts-healthy-hydration/"
                    )
                } header: {
                    Text("Hydration")
                }
                
                Section {
                    CitationRow(
                        title: "Meal Timing & Frequency",
                        description: "International Society of Sports Nutrition",
                        url: "https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0189-4"
                    )
                    
                    CitationRow(
                        title: "Intermittent Fasting",
                        description: "Harvard Medical School",
                        url: "https://www.health.harvard.edu/blog/intermittent-fasting-surprising-update-2018062914156"
                    )
                } header: {
                    Text("Nutrition Timing")
                }
                
                Section {
                    CitationRow(
                        title: "Food Database",
                        description: "USDA FoodData Central",
                        url: "https://fdc.nal.usda.gov/"
                    )
                    
                    CitationRow(
                        title: "Nutritional Analysis",
                        description: "Nutrition AI uses established databases and published nutritional values",
                        url: nil
                    )
                } header: {
                    Text("Food Recognition & Analysis")
                }
                
                Section {
                    Text("This app is designed for general wellness and informational purposes. The calculations and recommendations are based on widely accepted scientific research and health guidelines.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    
                    Text("⚠️ Important: Always consult with a healthcare professional or registered dietitian before starting any diet, exercise program, or making significant changes to your health routine.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                } header: {
                    Text("Disclaimer")
                }
            }
            .navigationTitle("Medical Citations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CitationRow: View {
    let title: String
    let description: String
    let url: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let url = url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Text("View Source")
                            .font(.caption)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MedicalCitationsView()
}
