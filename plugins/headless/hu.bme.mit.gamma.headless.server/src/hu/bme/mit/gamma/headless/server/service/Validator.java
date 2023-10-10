package hu.bme.mit.gamma.headless.server.service;

import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.SystemUtils;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;

// The Validator class checks if an operation can be executed on a project or workspace
public class Validator {

	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";

	public static final String PROJECT_DESCRIPTOR_JSON = "projectDescriptor.json";
	public static final String UNDER_OPERATION_PROPERTY = "underOperation";

	// Checks whether a workspace already exists or not
	public static boolean checkIfWorkspaceExists(String workspace) throws IOException {
		Map<String, Set<String>> projectsByWorkspace = FileHandlerUtil.getProjectsByWorkspaces();
		return projectsByWorkspace.containsKey(workspace);
	}

	// Checks whether a project already exists under a workspace or not
	public static boolean checkIfProjectAlreadyExistsUnderWorkspace(String workspace, String projectName)
			throws IOException {
		Map<String, Set<String>> projectsByWorkspace = FileHandlerUtil.getProjectsByWorkspaces();
		Set<String> projects = projectsByWorkspace.getOrDefault(workspace, Collections.emptySet());
		return projects.contains(projectName);
	}

	// Checks if the operation ended abruptly in a project
	// If the process with the PID of the operation is no longer running, yet the
	// project project descriptor states so,
	// then there must be an error
	public static boolean checkIfProjectHasRunIntoError(String workspace, String projectName) throws IOException {
		boolean isUnderLoad = false;
		int pid = FileHandlerUtil.getPid(workspace, projectName);
		boolean validPid = false;

		validPid = isValidPid(pid);
		isUnderLoad = checkIfProjectIsUnderLoad(workspace, projectName);

		if (isUnderLoad && !validPid) {
			return true;
		} else if (!isUnderLoad && validPid) {
			return true;
		} else {
			return false;
		}

	}

	// Checks if there's an undergoing operation on a project
	public static boolean checkIfProjectIsUnderLoad(String workspace, String projectName) throws IOException {
		File jsonFile = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ File.separator + projectName + File.separator + PROJECT_DESCRIPTOR_JSON);
		if (!jsonFile.exists()) {
			return false;
		}
		String jsonString = FileUtils.readFileToString(jsonFile);
		JsonElement jElement = new JsonParser().parse(jsonString);
		JsonObject jObject = jElement.getAsJsonObject();
		return jObject.get(UNDER_OPERATION_PROPERTY) != null && jObject.get(UNDER_OPERATION_PROPERTY).getAsBoolean();

	}

	public static boolean isValidPid(int pid) {

		String exportedEclipse = SystemUtils.IS_OS_WINDOWS ? "eclipse.exe" : "eclipse";

		return ProcessHandle.allProcesses()
				.anyMatch(process -> text(process.info().command()).contains(exportedEclipse) && process.pid() == pid);

	}

	private static String text(Optional<?> optional) {
		return optional.map(Object::toString).orElse("-");
	}

}
