package it.unife.spf.gateway.processingstrategies;

import java.util.Arrays;
import java.util.ArrayList;

public abstract class BasicProcessingStrategy {

  public ArrayList<String> types;
  public String pipelineId;
  private String parentClassName;

  /**
   * Constructor for creating a basic processing strategy
   *
   * @param types
   * @param pipelineId
   * @param parentClassName
   *
   */
  public BasicProcessingStrategy(ArrayList<String> types, String pipelineId, String parentClassName) {
    this.types = new ArrayList<String>(types);
    this.pipelineId = pipelineId;
    this.parentClassName = parentClassName;
  }

  public String getPipelineId() {
    return this.pipelineId;
  }

  public ArrayList<String> getTypes() {
    return this.types;
  }

  public void activate() {
  }

  public void deactivate() {
  }

  public boolean interestedIn(String type) {
    return Arrays.asList(this.types).contains(type);
  }

  public void InformationDiff(byte[] raw_data, byte[] old_data) {
    // TODO raise "*** #{BasicProcessingStrategy.name} < #{@parent_class_name}: Parent class needs to implement the information_diff method! ***"
  }

  public void DoProcess(byte[] raw_data) {
    // TODO raise "*** #{BasicProcessingStrategy.name} < #{@parent_class_name}: Parent class needs to implement the do_process method! ***"
  }

}
