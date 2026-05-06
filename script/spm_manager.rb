# frozen_string_literal: true

#
# © 2026-present https://github.com/cengiz-pz
#

require 'xcodeproj'

def print_usage
	puts 'Usage: ruby spm_manager.rb -a|-d [--target <name>] [--no-link] <xcodeproj> <url> <version> <product>'
	puts ''
	puts 'Options:'
	puts '  -a              Add the specified SPM dependency to the Xcode project'
	puts '  -d              Remove the specified SPM dependency from the Xcode project'
	puts '  --target <name> Xcode target to modify. Defaults to the first target.'
	puts '  --no-link       Add to packageProductDependencies (compile) but NOT to the'
	puts '                  Frameworks build phase (link). Use this for static library'
	puts '                  targets that need to compile against a framework without'
	puts '                  embedding it — prevents duplicate symbols at link time when'
	puts '                  the consuming app also links the same framework.'
	puts ''
	puts 'Examples:'
	puts '  # Add to first target, linked (original behaviour):'
	puts '  ruby spm_manager.rb -a MyApp.xcodeproj https://github.com/firebase-ios-sdk 11.0.0 FirebaseAuth'
	puts ''
	puts '  # Add to module target, compile-only (no link) — for static library targets:'
	puts '  ruby spm_manager.rb -a --target firebase_plugin --no-link \\'
	puts '      MyApp.xcodeproj https://github.com/firebase-ios-sdk 11.0.0 FirebaseAuth'
	puts ''
	puts '  # Add to test target, linked:'
	puts '  ruby spm_manager.rb -a --target firebase_plugin_tests \\'
	puts '      MyApp.xcodeproj https://github.com/firebase-ios-sdk 11.0.0 FirebaseAuth'
end

# ---------------------------------------------------------------------------
# Argument parsing
# Supports optional --target <name> and --no-link flags between the action
# and the four positional arguments so the script remains backwards-compatible
# when neither flag is supplied.
# ---------------------------------------------------------------------------

if ARGV.length < 5
	print_usage
	exit 1
end

option      = ARGV[0]
target_name = nil
no_link     = false

remaining = ARGV[1..]

# Consume flags
loop do
	case remaining[0]
	when '--target'
		if remaining[1].nil? || remaining[1].start_with?('-')
			puts "Error: --target requires a target name argument."
			puts ''
			print_usage
			exit 1
		end
		target_name = remaining[1]
		remaining   = remaining[2..]
	when '--no-link'
		no_link   = true
		remaining = remaining[1..]
	else
		break
	end
end

if remaining.length != 4
	print_usage
	exit 1
end

project_path, url, version, product_name = remaining
url          = url.strip
version      = version.strip
product_name = product_name.strip

unless ['-a', '-d'].include?(option)
	puts "Error: Unknown option '#{option}'. Must be -a (add) or -d (remove)."
	puts ''
	print_usage
	exit 1
end

unless File.exist?(project_path)
	puts "Error: Xcode project not found at #{project_path}"
	exit 1
end

if url.empty? || version.empty? || product_name.empty?
	puts 'Error: url, version, and product_name must all be non-empty.'
	exit 1
end

# ---------------------------------------------------------------------------
# Xcode Project Manipulation
# ---------------------------------------------------------------------------
begin
	project = Xcodeproj::Project.open(project_path)

	# Resolve the target by name when --target is given, else use first target.
	target =
		if target_name
			found = project.targets.find { |t| t.name == target_name }
			unless found
				available = project.targets.map(&:name).join(', ')
				puts "Error: Target '#{target_name}' not found. Available targets: #{available}"
				exit 1
			end
			found
		else
			project.targets.first
		end

	if target.nil?
		puts 'Error: No targets found in the Xcode project.'
		exit 1
	end

	if option == '-a'
		existing_dep = target.package_product_dependencies.find do |dep|
			dep.product_name == product_name
		end

		if existing_dep
			puts "Warning: Product dependency '#{product_name}' already exists in " \
				"target '#{target.name}'. Skipping add.\n\n"
		else
			# Reuse an existing XCRemoteSwiftPackageReference or create one.
			pkg = project.root_object.package_references.find do |p|
				p.repositoryURL == url
			end

			if pkg
				puts "Reusing existing package reference for '#{url}'."
			else
				pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
				pkg.repositoryURL = url
				pkg.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => version }
				project.root_object.package_references << pkg
			end

			# Always add to packageProductDependencies (makes the module visible
			# to the Swift compiler for this target).
			ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
			ref.product_name = product_name
			ref.package = pkg
			target.package_product_dependencies << ref

			if no_link
				# --no-link: compile-only. Skip adding a PBXBuildFile to the
				# Frameworks build phase. The Swift compiler resolves the module
				# through packageProductDependencies; the linker never sees it,
				# so no symbols are archived into the static library output.
				puts "Successfully added SPM dependency '#{product_name}' " \
					"(#{url} @ #{version}) to target '#{target.name}' " \
					"[compile-only, not linked] in #{File.basename(project_path)}\n\n"
			else
				# Default: also add to the Frameworks build phase so the product
				# is linked into the target's binary (original behaviour).
				frameworks_phase = target.frameworks_build_phase
				frameworks_phase.add_file_reference(ref)
				puts "Successfully added SPM dependency '#{product_name}' " \
					"(#{url} @ #{version}) to target '#{target.name}' " \
					"[compile + link] in #{File.basename(project_path)}\n\n"
			end
		end

	elsif option == '-d'
		dep_to_remove = target.package_product_dependencies.find do |dep|
			dep.product_name == product_name
		end

		if dep_to_remove
			# Remove from the Frameworks build phase if present.
			frameworks_phase = target.frameworks_build_phase
			bf = frameworks_phase.files.find do |f|
				f.product_ref == dep_to_remove
			end
			frameworks_phase.remove_file_reference(bf.file_ref) if bf

			target.package_product_dependencies.delete(dep_to_remove)
			dep_to_remove.remove_from_project
			puts "Removed product dependency '#{product_name}' from target '#{target.name}'."
		else
			puts "Warning: Product dependency '#{product_name}' not found in " \
				"target '#{target.name}'. Skipping.\n\n"
		end

		# Only remove the shared package reference if no target across the whole
		# project still depends on it.
		pkg_to_remove = project.root_object.package_references.find do |p|
			p.repositoryURL == url
		end

		if pkg_to_remove
			still_in_use = project.targets.any? do |t|
				t.package_product_dependencies.any? { |dep| dep.package == pkg_to_remove }
			end

			if still_in_use
				puts "Package reference '#{url}' is still used by other products. Keeping it.\n\n"
			else
				project.root_object.package_references.delete(pkg_to_remove)
				pkg_to_remove.remove_from_project
				puts "Removed package reference '#{url}'.\n\n"
			end
		else
			puts "Warning: Package reference '#{url}' not found in project. Skipping.\n\n"
		end

		puts "Successfully removed SPM dependency '#{product_name}' from " \
			"target '#{target.name}' in #{File.basename(project_path)}\n\n"
	end

	project.save
rescue StandardError => e
	puts "An error occurred: #{e.message}\n\n"
	exit 1
end
